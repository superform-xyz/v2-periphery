// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";

import { SuperGovernor } from "../../../src/SuperGovernor.sol";
import { SuperVaultAggregatorV2 } from "../../../src/SuperVault/SuperVaultAggregatorV2.sol";
import { SuperVaultV2 } from "../../../src/SuperVault/SuperVaultV2.sol";
import { SuperVaultStrategyV2 } from "../../../src/SuperVault/SuperVaultStrategyV2.sol";
import { SuperVaultEscrow } from "../../../src/SuperVault/SuperVaultEscrow.sol";
import { ISuperVaultAggregator } from "../../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ISuperVaultStrategy } from "../../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { MockSuperOracle } from "../../mocks/MockSuperOracle.sol";
import { MockUp } from "../../mocks/MockUp.sol";

/// @title SuperVaultReceiversForkTest
/// @notice Fork integration tests verifying SuperVaultStrategy handles ERC721, ERC1155,
///         ERC1271, and ERC165 with real on-chain token contracts.
///
/// @dev ERC721 note: onERC721Received is only invoked by contracts that call _safeMint or
///      safeTransferFrom. Protocols that use plain _mint (e.g. Uniswap V3 NonfungiblePositionManager)
///      bypass the callback entirely. We therefore use BAYC, which calls _safeMint during minting,
///      as the canonical ERC721 example.
///
/// @dev Forks Ethereum mainnet. Addresses and holders verified via cast at time of writing.
contract SuperVaultReceiversForkTest is Test {
    /*//////////////////////////////////////////////////////////////
                    REAL ETHEREUM MAINNET ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @dev Bored Ape Yacht Club - uses _safeMint, so onERC721Received IS invoked on the recipient.
    ///      Source: https://etherscan.io/address/0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D#code
    ///      mintApe() calls _safeMint(msg.sender, i) for each token.
    address constant BAYC = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;

    /// @dev Owner of BAYC #1 on Ethereum mainnet
    ///      Verified: cast call 0xBC4CA...3D "ownerOf(uint256)(address)" 1 --rpc-url $ETH
    address constant BAYC_TOKEN1_OWNER = 0x46EFbAedc92067E6d60E84ED6395099723252496;
    uint256 constant BAYC_TOKEN_ID = 1;

    /// @dev Owner of BAYC #2 on Ethereum mainnet (used in multi-transfer test)
    ///      Verified: cast call 0xBC4CA...3D "ownerOf(uint256)(address)" 2 --rpc-url $ETH
    address constant BAYC_TOKEN2_OWNER = 0xc5c7b46843014B1591e9aF24de797156cde67f08;
    uint256 constant BAYC_TOKEN_ID2 = 2;

    /// @dev Rarible shared ERC1155 contract on Ethereum
    ///      Verified: supportsInterface(0xd9b67a26) == true
    address constant RARIBLE_ERC1155 = 0xd07dc4262BCDbf85190C01c996b4C06a461d2430;

    /// @dev Holder of Rarible token ID 1 (balance = 10, verified on-chain)
    ///      Verified: cast call 0xd07dc4...30 "balanceOf(address,uint256)(uint256)" $HOLDER 1 --rpc-url $ETH
    address constant RARIBLE_TOKEN1_HOLDER = 0xe4c33e64A006f286B6B831cF468F7f5D50FFeaC5;
    uint256 constant RARIBLE_TOKEN_ID = 1;

    /// @dev USDC on Ethereum mainnet - used as the vault's underlying asset
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    /*//////////////////////////////////////////////////////////////
                            TEST STATE
    //////////////////////////////////////////////////////////////*/

    SuperVaultStrategyV2 public strategy;
    address public sGovernor;
    address public manager;

    /*//////////////////////////////////////////////////////////////
                                SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        vm.createSelectFork(vm.envString("ETHEREUM_RPC_URL"));

        sGovernor = makeAddr("sGovernor");
        manager = makeAddr("manager");
        address bank = makeAddr("bank");

        // Deploy fresh governance with new implementation code
        SuperGovernor superGovernor = new SuperGovernor(
            sGovernor, // super governor (admin)
            manager, // governor
            manager, // bankManager
            manager, // oracleManager
            manager, // gasManager
            manager, // guardian
            manager, // treasury
            false // upkeepPaymentsEnabled
        );

        // Deploy V2 implementations (carries ERC721/ERC1155/ERC1271 support + B20 precompile asset support)
        address vaultImpl = address(new SuperVaultV2(address(superGovernor)));
        address strategyImpl = address(new SuperVaultStrategyV2(address(superGovernor)));
        address escrowImpl = address(new SuperVaultEscrow());

        // Deploy V2 aggregator pointing at V2 implementations
        SuperVaultAggregatorV2 aggregator =
            new SuperVaultAggregatorV2(address(superGovernor), vaultImpl, strategyImpl, escrowImpl);

        // Register required governor addresses
        address upToken = address(new MockUp(address(this)));
        address superOracle = address(new MockSuperOracle(1e18));

        vm.startPrank(sGovernor);
        superGovernor.setAddress(superGovernor.UP(), upToken);
        superGovernor.setAddress(superGovernor.UPKEEP_TOKEN(), upToken);
        superGovernor.setAddress(superGovernor.SUPER_BANK(), bank);
        superGovernor.setAddress(superGovernor.SUPER_ORACLE(), superOracle);
        superGovernor.setAddress(superGovernor.SUPER_VAULT_AGGREGATOR(), address(aggregator));
        vm.stopPrank();

        // Create vault with real USDC on Ethereum mainnet
        vm.prank(manager);
        (, address strategyAddr,) = aggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: USDC,
                name: "USDC SuperVault",
                symbol: "svUSDC",
                mainManager: manager,
                secondaryManagers: new address[](0),
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: 0,
                    managementFeeBps: 0,
                    recipient: manager
                })
            })
        );

        strategy = SuperVaultStrategyV2(payable(strategyAddr));
    }

    /*//////////////////////////////////////////////////////////////
                        ERC721 FORK TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice BAYC token (minted with _safeMint) can be sent to the strategy via safeTransferFrom,
    ///         which invokes onERC721Received on the strategy contract.
    function test_Fork_ERC721_BAYCTransferToStrategy() public {
        assertEq(
            IERC721(BAYC).ownerOf(BAYC_TOKEN_ID),
            BAYC_TOKEN1_OWNER,
            "owner of BAYC #1 changed - update constant"
        );

        vm.prank(BAYC_TOKEN1_OWNER);
        IERC721(BAYC).safeTransferFrom(BAYC_TOKEN1_OWNER, address(strategy), BAYC_TOKEN_ID);

        assertEq(IERC721(BAYC).ownerOf(BAYC_TOKEN_ID), address(strategy), "strategy should own BAYC #1");
    }

    /// @notice Strategy can hold multiple ERC721 tokens from the same collection
    function test_Fork_ERC721_StrategyCanHoldMultipleBAYC() public {
        vm.prank(BAYC_TOKEN1_OWNER);
        IERC721(BAYC).safeTransferFrom(BAYC_TOKEN1_OWNER, address(strategy), BAYC_TOKEN_ID);

        // BAYC #1 and #2 are owned by the same address
        vm.prank(BAYC_TOKEN2_OWNER);
        IERC721(BAYC).safeTransferFrom(BAYC_TOKEN2_OWNER, address(strategy), BAYC_TOKEN_ID2);

        assertEq(IERC721(BAYC).ownerOf(BAYC_TOKEN_ID), address(strategy));
        assertEq(IERC721(BAYC).ownerOf(BAYC_TOKEN_ID2), address(strategy));
    }

    /*//////////////////////////////////////////////////////////////
                        ERC1155 FORK TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Rarible ERC1155 token can be sent to the strategy via safeTransferFrom,
    ///         which invokes onERC1155Received on the strategy contract.
    function test_Fork_ERC1155_RaribleTokenTransferToStrategy() public {
        uint256 holderBalance = IERC1155(RARIBLE_ERC1155).balanceOf(RARIBLE_TOKEN1_HOLDER, RARIBLE_TOKEN_ID);
        assertGt(holderBalance, 0, "holder has no balance - update constant");

        vm.prank(RARIBLE_TOKEN1_HOLDER);
        IERC1155(RARIBLE_ERC1155).safeTransferFrom(RARIBLE_TOKEN1_HOLDER, address(strategy), RARIBLE_TOKEN_ID, 1, "");

        assertEq(
            IERC1155(RARIBLE_ERC1155).balanceOf(address(strategy), RARIBLE_TOKEN_ID),
            1,
            "strategy should hold 1 Rarible token"
        );
        assertEq(
            IERC1155(RARIBLE_ERC1155).balanceOf(RARIBLE_TOKEN1_HOLDER, RARIBLE_TOKEN_ID),
            holderBalance - 1,
            "holder balance should decrease by 1"
        );
    }

    /// @notice Strategy can receive a partial amount of a fungible ERC1155 token
    function test_Fork_ERC1155_PartialTransferToStrategy() public {
        vm.prank(RARIBLE_TOKEN1_HOLDER);
        IERC1155(RARIBLE_ERC1155).safeTransferFrom(RARIBLE_TOKEN1_HOLDER, address(strategy), RARIBLE_TOKEN_ID, 5, "");

        assertEq(IERC1155(RARIBLE_ERC1155).balanceOf(address(strategy), RARIBLE_TOKEN_ID), 5);
    }

    /*//////////////////////////////////////////////////////////////
                    ERC1271 isValidSignature FORK TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice isValidSignature returns the ERC1271 magic value on a live fork
    function test_Fork_ERC1271_IsValidSignatureReturnsMagicValue() public view {
        bytes32 hash = keccak256("some off-chain message");
        bytes memory sig = hex"deadbeef";

        bytes4 magic = strategy.isValidSignature(hash, sig);
        assertEq(magic, IERC1271.isValidSignature.selector, "must return ERC1271 magic value");
    }

    /// @notice isValidSignature accepts any hash and any signature data
    function test_Fork_ERC1271_IsValidSignatureAnyInput() public view {
        assertEq(strategy.isValidSignature(bytes32(0), ""), IERC1271.isValidSignature.selector);
        assertEq(
            strategy.isValidSignature(bytes32(type(uint256).max), abi.encode(address(this), uint256(42))),
            IERC1271.isValidSignature.selector
        );
    }

    /*//////////////////////////////////////////////////////////////
                    ERC165 supportsInterface FORK TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice supportsInterface correctly advertises all supported interfaces on a live fork
    function test_Fork_SupportsInterface_AllDeclared() public view {
        assertTrue(strategy.supportsInterface(type(IERC721Receiver).interfaceId), "IERC721Receiver");
        assertTrue(strategy.supportsInterface(type(IERC1155Receiver).interfaceId), "IERC1155Receiver");
        assertTrue(strategy.supportsInterface(type(IERC1271).interfaceId), "IERC1271");
        assertTrue(strategy.supportsInterface(type(IERC165).interfaceId), "IERC165");
    }

    /// @notice supportsInterface returns false for unsupported interfaces
    function test_Fork_SupportsInterface_UnknownReturnsFalse() public view {
        assertFalse(strategy.supportsInterface(0xdeadbeef));
        assertFalse(strategy.supportsInterface(0x00000000));
    }

    /// @notice The Rarible contract recognises strategy as an ERC1155 receiver via supportsInterface
    ///         - this is the actual check Rarible performs before safeTransferFrom
    function test_Fork_ERC1155_RaribleChecksSupportsInterface() public view {
        bool supported = strategy.supportsInterface(type(IERC1155Receiver).interfaceId);
        assertTrue(supported, "Rarible requires recipient to support IERC1155Receiver");
    }
}
