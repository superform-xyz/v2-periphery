// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { ISuperGovernor } from "../../../src/interfaces/ISuperGovernor.sol";
import { CrossChainPositionRegistry } from "../../../src/CrossChain/CrossChainPositionRegistry.sol";
import { CrossChainAUMOracle } from "../../../src/CrossChain/CrossChainAUMOracle.sol";
import { CrossChainPositionCapGuard } from "../../../src/CrossChain/CrossChainPositionCapGuard.sol";
import { ICrossChainPositionRegistry } from "../../../src/interfaces/CrossChain/ICrossChainPositionRegistry.sol";
import { ICrossChainAUMOracle } from "../../../src/interfaces/CrossChain/ICrossChainAUMOracle.sol";
import { ICrossChainPositionCapGuard } from "../../../src/interfaces/CrossChain/ICrossChainPositionCapGuard.sol";

/// @notice Fork test validating the three cross-chain contracts against the REAL deployed
///         SuperGovernor + SuperVaultAggregator on Base: real getAddress/setAddress, role checks,
///         validator quorum (getPPSOracleQuorum/isValidator), and aggregator.isMainManager.
///         Proves our integration-point assumptions match production ABIs/behaviour.
contract CrossChainForkFlowTest is Test {
    // Base mainnet (script/output/prod/8453/Base-latest.json)
    address internal constant SUPER_GOVERNOR = 0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4;
    address internal constant SUPER_VAULT_AGGREGATOR = 0x10AC0b33e1C4501CF3ec1cB1AE51ebfdbd2d4698;

    bytes32 internal constant CROSS_CHAIN_POSITION_REGISTRY = keccak256("CROSS_CHAIN_POSITION_REGISTRY");
    bytes32 internal constant CROSS_CHAIN_AUM_ORACLE = keccak256("CROSS_CHAIN_AUM_ORACLE");
    bytes32 internal constant CROSS_CHAIN_CAP_GUARD = keccak256("CROSS_CHAIN_CAP_GUARD");
    bytes32 internal constant SUPER_VAULT_AGGREGATOR_KEY = keccak256("SUPER_VAULT_AGGREGATOR");

    bytes32 internal constant UPDATE_AUM_TYPEHASH = keccak256(
        "UpdateAUM(address strategy,bytes32 positionIdsHash,bytes32 valuesHash,uint256 hubAssets,uint256 timestamp,uint256 nonce)"
    );

    ISuperGovernor internal governor;
    CrossChainPositionRegistry internal registry;
    CrossChainAUMOracle internal oracle;
    CrossChainPositionCapGuard internal guard;

    address internal strategy = makeAddr("strategy");
    address internal registrar = makeAddr("registrar");
    address internal bridgeHook = makeAddr("bridgeHook");
    address internal destVault = makeAddr("destVault");
    uint64 internal constant CHAIN_A = 42_161;

    uint256[] internal pks;

    function setUp() public {
        vm.createSelectFork(vm.envOr("BASE_RPC_URL", string("https://mainnet.base.org")));
        governor = ISuperGovernor(SUPER_GOVERNOR);

        registry = new CrossChainPositionRegistry(SUPER_GOVERNOR);
        oracle = new CrossChainAUMOracle(SUPER_GOVERNOR, "SuperformCrossChainAUM", "1");
        guard = new CrossChainPositionCapGuard(SUPER_GOVERNOR);

        // Grant the roles our contracts require to this test contract (real OZ AccessControl, slot 0).
        _grantRole(governor.GOVERNOR_ROLE(), address(this));
        _grantRole(governor.SUPER_GOVERNOR_ROLE(), address(this));
        _grantRole(governor.ORACLE_MANAGER_ROLE(), address(this));

        // Register the three keys in the REAL governor registry (validates getAddress/setAddress).
        governor.setAddress(CROSS_CHAIN_POSITION_REGISTRY, address(registry));
        governor.setAddress(CROSS_CHAIN_AUM_ORACLE, address(oracle));
        governor.setAddress(CROSS_CHAIN_CAP_GUARD, address(guard));

        // Install 3 test validators + quorum 2 on the real governor (GOVERNOR_ROLE-gated).
        uint256[] memory raw = new uint256[](3);
        raw[0] = 0xA11CE;
        raw[1] = 0xB0B;
        raw[2] = 0xC0FFEE;
        // sort ascending by address for signature ordering
        for (uint256 i; i < 3; ++i) {
            for (uint256 j = i + 1; j < 3; ++j) {
                if (vm.addr(raw[j]) < vm.addr(raw[i])) (raw[i], raw[j]) = (raw[j], raw[i]);
            }
        }
        address[] memory validators = new address[](3);
        bytes[] memory pubkeys = new bytes[](3);
        for (uint256 i; i < 3; ++i) {
            pks.push(raw[i]);
            validators[i] = vm.addr(raw[i]);
            pubkeys[i] = hex"00";
        }
        governor.setValidatorConfig(1, validators, pubkeys, 2, "");

        // Wire our contracts (all gated by REAL role checks on the real governor).
        registry.setRegistrar(strategy, registrar);
        registry.setBridgeHookAuthorization(bridgeHook, true);
        guard.setApprovedDestination(strategy, CHAIN_A, destVault, true);
        _setCapConfig(7000, 800e18);
        oracle.setAUMOracleConfig(
            strategy,
            ICrossChainAUMOracle.AUMOracleConfig({
                maxStaleness: 1 hours,
                minUpdateInterval: 1 minutes,
                deviationThreshold: 0.5e18,
                perPositionDeviationThreshold: 0.75e18,
                consistencyToleranceBps: 100,
                maxConsecutiveDeviationBreaches: 2
            })
        );
    }

    /*//////////////////////////////////////////////////////////////
                        REAL-ABI ASSUMPTION CHECKS
    //////////////////////////////////////////////////////////////*/

    function test_Fork_GovernorRegistryResolvesOurContracts() public view {
        assertEq(governor.getAddress(CROSS_CHAIN_POSITION_REGISTRY), address(registry));
        assertEq(governor.getAddress(CROSS_CHAIN_AUM_ORACLE), address(oracle));
        assertEq(governor.getAddress(CROSS_CHAIN_CAP_GUARD), address(guard));
        // The production aggregator key resolves to the real aggregator our cap guard reads.
        assertEq(governor.getAddress(SUPER_VAULT_AGGREGATOR_KEY), SUPER_VAULT_AGGREGATOR);
    }

    function test_Fork_ValidatorQuorumWired() public view {
        assertEq(governor.getPPSOracleQuorum(), 2);
        assertTrue(governor.isValidator(vm.addr(pks[0])));
        assertTrue(governor.getValidatorsCount() >= 2);
    }

    function test_Fork_RoleGatingUsesRealGovernor() public {
        // A non-role account cannot call our governor-gated setters.
        vm.prank(makeAddr("rando"));
        vm.expectRevert(ICrossChainPositionRegistry.UNAUTHORIZED_CONFIG.selector);
        registry.setRegistrar(strategy, makeAddr("x"));

        vm.prank(makeAddr("rando"));
        vm.expectRevert(ICrossChainPositionCapGuard.UNAUTHORIZED.selector);
        guard.setApprovedDestination(strategy, CHAIN_A, makeAddr("v"), true);
    }

    /*//////////////////////////////////////////////////////////////
                          FULL FLOW ON FORK
    //////////////////////////////////////////////////////////////*/

    function test_Fork_FullFlow() public {
        // 1. in-flight bridge recorded
        vm.prank(bridgeHook);
        registry.recordBridgedOut(strategy, CHAIN_A, 100e18);

        // 2. register approved SuperVault position
        vm.prank(registrar);
        bytes32 id = registry.registerPosition(
            strategy, CHAIN_A, ICrossChainPositionRegistry.PositionKind.SuperVault, destVault, 100e18, 95e18
        );

        // 3. quorum-signed report (uses REAL isValidator + getPPSOracleQuorum) confirms it
        _forwardAUM(id, 100e18, 900e18);
        assertEq(uint256(registry.positions(id).status), uint256(ICrossChainPositionRegistry.PositionStatus.Active));
        assertEq(oracle.getTotalAUM(strategy), 1000e18);

        // 4. cap guard validates against real AUM/exposure
        guard.validateAllocation(strategy, CHAIN_A, destVault, 500e18);
        vm.expectRevert(ICrossChainPositionCapGuard.CROSS_CHAIN_CAP_EXCEEDED.selector);
        guard.validateAllocation(strategy, CHAIN_A, destVault, 650e18);
    }

    function test_Fork_AggregatorIsMainManagerCallable() public {
        // The real aggregator's isMainManager must be callable (returns false for a synthetic
        // strategy) - proves the cap guard's manager-resolution ABI matches production.
        (bool ok, bytes memory ret) = SUPER_VAULT_AGGREGATOR.staticcall(
            abi.encodeWithSignature("isMainManager(address,address)", makeAddr("mgr"), strategy)
        );
        assertTrue(ok, "isMainManager reverted - ABI mismatch");
        assertFalse(abi.decode(ret, (bool)));
    }

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/

    function _grantRole(bytes32 role, address account) internal {
        bytes32 roleSlot = keccak256(abi.encode(role, uint256(0)));
        bytes32 memberSlot = keccak256(abi.encode(account, roleSlot));
        vm.store(SUPER_GOVERNOR, memberSlot, bytes32(uint256(1)));
        require(governor.hasRole(role, account), "role grant via storage failed");
    }

    function _setCapConfig(uint256 bps, uint256 cap) internal {
        uint64[] memory chains = new uint64[](1);
        chains[0] = CHAIN_A;
        uint256[] memory caps = new uint256[](1);
        caps[0] = cap;
        bool[] memory en = new bool[](1);
        en[0] = true;
        guard.setCapConfig(strategy, bps, chains, caps, en);
    }

    function _forwardAUM(bytes32 id, uint256 value, uint256 hubAssets) internal {
        bytes32[] memory ids = new bytes32[](1);
        ids[0] = id;
        uint256[] memory vals = new uint256[](1);
        vals[0] = value;
        uint256 ts = block.timestamp;
        bytes32 structHash = keccak256(
            abi.encode(
                UPDATE_AUM_TYPEHASH,
                strategy,
                keccak256(abi.encodePacked(ids)),
                keccak256(abi.encodePacked(vals)),
                hubAssets,
                ts,
                oracle.noncePerStrategy(strategy)
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", oracle.domainSeparator(), structHash));
        bytes[] memory proofs = new bytes[](2);
        for (uint256 i; i < 2; ++i) {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(pks[i], digest);
            proofs[i] = abi.encodePacked(r, s, v);
        }
        oracle.forwardAUM(strategy, ids, vals, hubAssets, ts, proofs);
    }
}
