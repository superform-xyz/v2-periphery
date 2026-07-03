// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

import { SuperGovernor } from "../../../src/SuperGovernor.sol";
import { SuperVaultAggregator } from "../../../src/SuperVault/SuperVaultAggregator.sol";
import { SuperVault } from "../../../src/SuperVault/SuperVault.sol";
import { SuperVaultStrategy } from "../../../src/SuperVault/SuperVaultStrategy.sol";
import { SuperVaultEscrow } from "../../../src/SuperVault/SuperVaultEscrow.sol";
import { ISuperVaultAggregator } from "../../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ISuperVaultStrategy } from "../../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { MockSuperOracle } from "../../mocks/MockSuperOracle.sol";
import { MockUp } from "../../mocks/MockUp.sol";

/// @title SuperVaultB20ForkTest
/// @notice Fork integration tests documenting V1 SuperVaultAggregator behavior with B20 tokens.
///
/// @dev B20 tokens are Base precompiles launched on 2025-06-25.
///      `eth_getCode` returns `0xef` (1 byte), so `code.length == 1`.
///
///      V1's `AssetMetadataLib.tryGetAssetDecimals` has TWO guards:
///        1. `if (asset_.code.length == 0) revert INVALID_ASSET()` -- PASSES for B20 (length is 1)
///        2. staticcall to `decimals()` -- FAILS for B20 (OpcodeNotFound, success == false)
///      Then `SuperVault.initialize` checks `if (!success) revert INVALID_ASSET()`.
///
///      Net result: V1 REJECTS B20 tokens with INVALID_ASSET() even though the code-length guard
///      does not fire. This test suite documents this behavior on a live Base Sepolia fork.
///
/// @dev Forks Base Sepolia. No pinned block (B20 launched 2025-06-25, always live).
contract SuperVaultB20ForkTest is Test {
    /*//////////////////////////////////////////////////////////////
                        BASE SEPOLIA ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @dev B20 precompile token on Base Sepolia -- eth_getCode returns 0xef (code.length == 1)
    address constant B20_TOKEN = 0xB20000000000000000000088139b89680101cd2A;

    /*//////////////////////////////////////////////////////////////
                            TEST STATE
    //////////////////////////////////////////////////////////////*/

    SuperVaultAggregator public aggregator;
    SuperGovernor public superGovernor;
    address public sGovernor;
    address public manager;

    /*//////////////////////////////////////////////////////////////
                                SETUP
    //////////////////////////////////////////////////////////////*/

    /// @dev Deploys a fresh V1 stack (governor + impls + aggregator) but does NOT call createVault,
    ///      because createVault reverts with INVALID_ASSET() when the asset is a B20 precompile.
    function setUp() public {
        string memory rpcUrl = vm.envOr("BASE_SEPOLIA_RPC_URL", string("https://sepolia.base.org"));
        vm.createSelectFork(rpcUrl);

        sGovernor = makeAddr("sGovernor");
        manager = makeAddr("manager");
        address bank = makeAddr("bank");

        // Deploy fresh governance
        superGovernor = new SuperGovernor(
            sGovernor, // super governor (admin)
            manager, // governor
            manager, // bankManager
            manager, // oracleManager
            manager, // gasManager
            manager, // guardian
            manager, // treasury
            false // upkeepPaymentsEnabled
        );

        // Deploy V1 implementations
        address vaultImpl = address(new SuperVault(address(superGovernor)));
        address strategyImpl = address(new SuperVaultStrategy(address(superGovernor)));
        address escrowImpl = address(new SuperVaultEscrow());

        // Deploy V1 aggregator
        aggregator = new SuperVaultAggregator(address(superGovernor), vaultImpl, strategyImpl, escrowImpl);

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
    }

    /*//////////////////////////////////////////////////////////////
                            FORK TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice B20 precompile returns the 0xef sentinel byte, so code.length == 1.
    ///         V1's first guard (`code.length == 0 → revert`) does NOT trigger.
    ///         However, the second guard (staticcall to decimals() returning success==false) does.
    function test_Fork_B20_CodeLengthIsNonZero() public view {
        assertEq(B20_TOKEN.code.length, 1, "B20 sentinel byte: code.length must be 1, not 0");
    }

    /// @notice Low-level staticcall to B20's decimals() returns success==false (OpcodeNotFound).
    ///         This is what causes V1 to ultimately reject B20 even though code.length != 0.
    function test_Fork_B20_DecimalsStaticCallFails() public view {
        (bool success,) = B20_TOKEN.staticcall(abi.encodeCall(IERC20Metadata.decimals, ()));
        assertFalse(success, "B20 decimals() staticcall must return success==false (OpcodeNotFound)");
    }

    /// @notice V1 createVault reverts with INVALID_ASSET() for a B20 asset.
    ///         Root cause: tryGetAssetDecimals passes the code.length guard but the decimals()
    ///         staticcall fails (OpcodeNotFound), so SuperVault.initialize reverts.
    function test_Fork_B20_CreateVaultRevertsInvalidAsset() public {
        vm.prank(manager);
        vm.expectRevert(bytes4(keccak256("INVALID_ASSET()")));
        aggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: B20_TOKEN,
                name: "B20 SuperVault",
                symbol: "svB20",
                mainManager: manager,
                secondaryManagers: new address[](0),
                minUpdateInterval: 5,
                maxStaleness: 1 weeks,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: 0,
                    managementFeeBps: 0,
                    recipient: manager
                })
            })
        );
    }
}
