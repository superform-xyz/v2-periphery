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
/// @notice Fork integration tests proving V1 SuperVaultAggregator is compatible with B20
///         precompile tokens on Base Sepolia.
///
/// @dev B20 tokens are Rust-level precompiles on Base, launched 2025-06-25.
///
///      WHY THESE TESTS USE vm.mockCall FOR decimals()
///      ================================================
///      On the real Base chain, calling decimals() on a B20 address works correctly (returns 18)
///      because the Base node has special Rust routing that intercepts calls to B20 addresses
///      and dispatches them to native precompile code.
///
///      However, Forge forks using revm (a pure EVM implementation). When revm encounters a
///      call to B20, it fetches the on-chain code via eth_getCode (which returns 0xef -- 1 byte),
///      caches it locally, and then tries to *execute* that byte as EVM bytecode. 0xef is the
///      EOF magic byte -- a deliberately invalid EVM opcode -- so revm returns OpcodeNotFound.
///
///      vm.mockCall intercepts the decimals() call before revm attempts execution, simulating
///      exactly what the real Base node does. The code.length == 1 assertion uses EXTCODESIZE
///      (no execution), so it reflects real on-chain state without hitting revm's limitation.
///
///      In a real production transaction on Base, both checks pass natively:
///        1. EXTCODESIZE(B20) == 1  ->  V1 guard (code.length == 0) does NOT fire
///        2. decimals() returns 18  ->  vault initializes with correct precision
contract SuperVaultB20ForkTest is Test {
    /*//////////////////////////////////////////////////////////////
                        BASE SEPOLIA ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @dev B20 precompile on Base Sepolia.
    ///      cast code 0xb20000000000000000000088139b89680101cd2a --rpc-url https://sepolia.base.org
    ///      => 0xef  (1 byte -- the EOF sentinel, set by the Base node for this precompile)
    ///      cast call 0xb20000000000000000000088139b89680101cd2a "decimals()(uint8)" --rpc-url https://sepolia.base.org
    ///      => 18
    address constant B20_TOKEN = 0xB20000000000000000000088139b89680101cd2A;

    /*//////////////////////////////////////////////////////////////
                            TEST STATE
    //////////////////////////////////////////////////////////////*/

    SuperVaultAggregator public aggregator;
    SuperGovernor public superGovernor;
    address public vault;
    address public sGovernor;
    address public manager;
    address public user;

    /*//////////////////////////////////////////////////////////////
                                SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        vm.createSelectFork("https://sepolia.base.org");

        sGovernor = makeAddr("sGovernor");
        manager = makeAddr("manager");
        user = makeAddr("user");
        address bank = makeAddr("bank");

        superGovernor = new SuperGovernor(
            sGovernor,
            manager,
            manager,
            manager,
            manager,
            manager,
            manager,
            false
        );

        address vaultImpl = address(new SuperVault(address(superGovernor)));
        address strategyImpl = address(new SuperVaultStrategy(address(superGovernor)));
        address escrowImpl = address(new SuperVaultEscrow());

        aggregator = new SuperVaultAggregator(address(superGovernor), vaultImpl, strategyImpl, escrowImpl);

        address upToken = address(new MockUp(address(this)));
        address superOracle = address(new MockSuperOracle(1e18));

        vm.startPrank(sGovernor);
        superGovernor.setAddress(superGovernor.UP(), upToken);
        superGovernor.setAddress(superGovernor.UPKEEP_TOKEN(), upToken);
        superGovernor.setAddress(superGovernor.SUPER_BANK(), bank);
        superGovernor.setAddress(superGovernor.SUPER_ORACLE(), superOracle);
        superGovernor.setAddress(superGovernor.SUPER_VAULT_AGGREGATOR(), address(aggregator));
        vm.stopPrank();

        // Mock decimals() to work around revm's inability to execute the 0xef precompile code.
        // On the real Base node, this call returns 18 natively. See contract-level NatSpec above.
        vm.mockCall(B20_TOKEN, abi.encodeCall(IERC20Metadata.decimals, ()), abi.encode(uint8(18)));

        vm.prank(manager);
        (vault,,) = aggregator.createVault(
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

    /*//////////////////////////////////////////////////////////////
                            FORK TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice B20 has code.length == 1 (the 0xef sentinel byte) on Base Sepolia.
    ///         V1's guard `if (asset_.code.length == 0) revert INVALID_ASSET()` does NOT fire.
    ///         This assertion reads real on-chain state via EXTCODESIZE -- no mock involved.
    function test_Fork_B20_CodeLengthIsOne() public view {
        assertEq(B20_TOKEN.code.length, 1, "B20 must have code.length == 1 (0xef sentinel)");
    }

    /// @notice V1 createVault succeeds with B20 as the underlying asset.
    ///         Proves the code.length guard is bypassed and vault initializes correctly.
    function test_Fork_B20_CreateVaultSucceeds() public view {
        assertNotEq(vault, address(0), "vault must be deployed");
        assertEq(SuperVault(vault).asset(), B20_TOKEN, "vault asset must be B20_TOKEN");
        assertEq(SuperVault(vault).PRECISION(), 10 ** 18, "PRECISION must reflect B20 decimals of 18");
    }
}
