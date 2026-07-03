// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { SuperGovernor } from "../../src/SuperGovernor.sol";
import { SuperVaultAggregatorV2 } from "../../src/SuperVault/SuperVaultAggregatorV2.sol";
import { SuperVaultV2 } from "../../src/SuperVault/SuperVaultV2.sol";
import { SuperVaultStrategyV2 } from "../../src/SuperVault/SuperVaultStrategyV2.sol";
import { SuperVaultEscrow } from "../../src/SuperVault/SuperVaultEscrow.sol";
import { ISuperVaultAggregator } from "../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ISuperVaultStrategy } from "../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";

import { MockERC20 } from "../mocks/MockERC20.sol";
import { MockUp } from "../mocks/MockUp.sol";
import { MockSuperOracle } from "../mocks/MockSuperOracle.sol";
import { MockERC721 } from "../mocks/MockERC721.sol";
import { MockERC1155 } from "../mocks/MockERC1155.sol";

import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";

/// @title SuperVaultV2Test
/// @notice Unit tests for SuperVaultStrategyV2 receiver interfaces:
///         ERC721Receiver, ERC1155Receiver, ERC1271 isValidSignature, ERC165 supportsInterface
contract SuperVaultV2Test is Test {
    SuperVaultStrategyV2 internal strategy;

    address internal sGovernor;
    address internal manager;
    address internal user;

    function setUp() public {
        sGovernor = makeAddr("sGovernor");
        manager = makeAddr("manager");
        user = makeAddr("user");

        MockERC20 asset = new MockERC20("Asset", "ASSET", 18);
        MockSuperOracle superOracle = new MockSuperOracle(1e18);

        SuperGovernor superGovernor =
            new SuperGovernor(sGovernor, manager, manager, manager, manager, manager, manager, false);

        address vaultImpl = address(new SuperVaultV2(address(superGovernor)));
        address strategyImpl = address(new SuperVaultStrategyV2(address(superGovernor)));
        address escrowImpl = address(new SuperVaultEscrow());

        SuperVaultAggregatorV2 aggregator =
            new SuperVaultAggregatorV2(address(superGovernor), vaultImpl, strategyImpl, escrowImpl);

        address upToken = address(new MockUp(address(this)));
        address superBank = makeAddr("superBank");

        vm.startPrank(sGovernor);
        superGovernor.setAddress(superGovernor.UP(), upToken);
        superGovernor.setAddress(superGovernor.UPKEEP_TOKEN(), upToken);
        superGovernor.setAddress(superGovernor.SUPER_BANK(), superBank);
        superGovernor.setAddress(superGovernor.SUPER_ORACLE(), address(superOracle));
        superGovernor.setAddress(superGovernor.SUPER_VAULT_AGGREGATOR(), address(aggregator));
        vm.stopPrank();

        vm.prank(manager);
        (, address strategyAddr,) = aggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                name: "Test Vault V2",
                symbol: "TV2",
                mainManager: manager,
                secondaryManagers: new address[](0),
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({ performanceFeeBps: 0, managementFeeBps: 0, recipient: manager })
            })
        );

        strategy = SuperVaultStrategyV2(payable(strategyAddr));
    }

    // =============================================================
    // onERC721Received Tests
    // =============================================================

    /// @notice onERC721Received returns the correct selector when called directly
    function test_OnERC721Received_ReturnsCorrectSelector() public view {
        bytes4 expected = IERC721Receiver.onERC721Received.selector;
        bytes4 returned = strategy.onERC721Received(address(0), address(0), 0, "");
        assertEq(returned, expected, "should return onERC721Received selector");
    }

    /// @notice Strategy can receive an ERC721 via safeTransferFrom
    function test_OnERC721Received_StrategyCanReceiveNFT() public {
        MockERC721 nft = new MockERC721();
        uint256 tokenId = 1;
        nft.mint(user, tokenId);

        vm.prank(user);
        nft.safeTransferFrom(user, address(strategy), tokenId);

        assertEq(nft.ownerOf(tokenId), address(strategy), "strategy should own the NFT");
    }

    /// @notice Strategy can hold multiple ERC721 tokens
    function test_OnERC721Received_StrategyCanReceiveMultipleNFTs() public {
        MockERC721 nft = new MockERC721();
        nft.mint(user, 1);
        nft.mint(user, 2);

        vm.startPrank(user);
        nft.safeTransferFrom(user, address(strategy), 1);
        nft.safeTransferFrom(user, address(strategy), 2);
        vm.stopPrank();

        assertEq(nft.ownerOf(1), address(strategy), "strategy should own token 1");
        assertEq(nft.ownerOf(2), address(strategy), "strategy should own token 2");
    }

    // =============================================================
    // onERC1155Received Tests
    // =============================================================

    /// @notice onERC1155Received returns the correct selector
    function test_OnERC1155Received_ReturnsCorrectSelector() public view {
        bytes4 expected = IERC1155Receiver.onERC1155Received.selector;
        bytes4 returned = strategy.onERC1155Received(address(0), address(0), 0, 0, "");
        assertEq(returned, expected, "should return onERC1155Received selector");
    }

    /// @notice Strategy can receive an ERC1155 token via safeTransferFrom
    function test_OnERC1155Received_StrategyCanReceiveSingle() public {
        MockERC1155 token = new MockERC1155();
        token.mint(user, 1, 100);

        vm.prank(user);
        token.safeTransferFrom(user, address(strategy), 1, 100, "");

        assertEq(token.balanceOf(address(strategy), 1), 100, "strategy should hold token balance");
    }

    /// @notice onERC1155BatchReceived returns the correct selector
    function test_OnERC1155BatchReceived_ReturnsCorrectSelector() public view {
        bytes4 expected = IERC1155Receiver.onERC1155BatchReceived.selector;
        bytes4 returned =
            strategy.onERC1155BatchReceived(address(0), address(0), new uint256[](0), new uint256[](0), "");
        assertEq(returned, expected, "should return onERC1155BatchReceived selector");
    }

    /// @notice Strategy can receive a batch of ERC1155 tokens
    function test_OnERC1155BatchReceived_StrategyCanReceiveBatch() public {
        MockERC1155 token = new MockERC1155();
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        amounts[0] = 50;
        amounts[1] = 200;

        token.mintBatch(user, ids, amounts);

        vm.prank(user);
        token.safeBatchTransferFrom(user, address(strategy), ids, amounts, "");

        assertEq(token.balanceOf(address(strategy), 1), 50, "strategy should hold token 1 balance");
        assertEq(token.balanceOf(address(strategy), 2), 200, "strategy should hold token 2 balance");
    }

    // =============================================================
    // isValidSignature (ERC1271) Tests
    // =============================================================

    /// @notice isValidSignature returns the ERC1271 magic value
    function test_IsValidSignature_ReturnsMagicValue() public view {
        bytes4 magic = strategy.isValidSignature(bytes32(0), "");
        assertEq(magic, IERC1271.isValidSignature.selector, "should return ERC1271 magic value");
    }

    /// @notice isValidSignature returns magic value for any hash and signature (fuzz)
    function test_IsValidSignature_AlwaysValid(bytes32 hash, bytes calldata sig) public view {
        bytes4 magic = strategy.isValidSignature(hash, sig);
        assertEq(magic, IERC1271.isValidSignature.selector, "should always return magic value");
    }

    // =============================================================
    // supportsInterface (ERC165) Tests
    // =============================================================

    function test_SupportsInterface_ERC721Receiver() public view {
        assertTrue(strategy.supportsInterface(type(IERC721Receiver).interfaceId));
    }

    function test_SupportsInterface_ERC1155Receiver() public view {
        assertTrue(strategy.supportsInterface(type(IERC1155Receiver).interfaceId));
    }

    function test_SupportsInterface_ERC1271() public view {
        assertTrue(strategy.supportsInterface(type(IERC1271).interfaceId));
    }

    function test_SupportsInterface_ERC165() public view {
        assertTrue(strategy.supportsInterface(type(IERC165).interfaceId));
    }

    function test_SupportsInterface_UnknownReturnsFalse() public view {
        assertFalse(strategy.supportsInterface(0xdeadbeef));
    }
}
