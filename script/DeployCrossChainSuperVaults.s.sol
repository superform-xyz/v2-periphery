// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { DeployV2Base } from "./DeployV2Base.s.sol";
import { console2 } from "forge-std/console2.sol";

import { CrossChainPositionRegistry } from "../src/CrossChain/CrossChainPositionRegistry.sol";
import { CrossChainAUMOracle } from "../src/CrossChain/CrossChainAUMOracle.sol";
import { CrossChainPositionCapGuard } from "../src/CrossChain/CrossChainPositionCapGuard.sol";
import { CrossChainHooksRootScreener } from "../src/CrossChain/CrossChainHooksRootScreener.sol";
import { ISuperGovernor } from "../src/interfaces/ISuperGovernor.sol";

/// @title DeployCrossChainSuperVaults
/// @notice Deploys the four cross-chain SuperVault periphery contracts on the HUB chain and prints
///         the complete governance bootstrap runbook (with calldata for the fixed steps). The
///         whole rollout is ADDITIVE: nothing on the deployed stack changes — SuperGovernor only
///         gains three address-book keys, one role grant, and configuration.
///
/// @dev DEPLOY (permissionless, deterministic):
///        forge script script/DeployCrossChainSuperVaults.s.sol --sig "run(uint256,uint64,address)" \
///          <env> <chainId> <superGovernor> --rpc-url ... --broadcast
///
///      GOVERNANCE BOOTSTRAP ORDER (Safe txs; calldata printed by this script):
///        1. superGovernor.setAddress(CROSS_CHAIN_POSITION_REGISTRY, registry)
///        2. superGovernor.setAddress(CROSS_CHAIN_AUM_ORACLE, oracle)
///        3. superGovernor.setAddress(CROSS_CHAIN_CAP_GUARD, capGuard)
///        4. superGovernor.grantRole(GUARDIAN_ROLE, screener)          (K3 veto authority)
///        Then per bridge protocol (use printHookAuthorization / printBanRawHook):
///        5. registry.setBridgeHookAuthorization(capHook, true)        per SuperVault*CapBridgeHook
///        6. screener.setBannedHook(rawHook, true)                     per raw bridge/transfer hook
///        Then per destination chain (use printDestinationPolicy):
///        7. capGuard.setDestinationAdapter(chainId, adapter, true)    per bridge adapter deployment
///        8. capGuard.setDestinationHooks(chainId, approveHook, depositHook)
///        9. capGuard.setEidChainId(eid, chainId)                      Stargate routes only (B4)
///        Then per strategy (use printStrategyOnboarding):
///        10. registry.setRegistrar(strategy, registrar)
///        11. screener.setScreenedStrategy(strategy, true)
///        12. capGuard.setApprovedDestination(strategy, chainId, vault, true)   per destination
///        13. capGuard.setCapConfig(strategy, maxBps, chainIds, caps, enabled)
///        14. oracle.setAUMOracleConfig(strategy, config)              (ORACLE_MANAGER_ROLE, not Safe)
///
///      ACTIVATION INVARIANT: steps 1-4 MUST land before any cap hook is included in a strategy
///      root — a cap hook whose SuperGovernor keys resolve to address(0) reverts every execution
///      (fail closed), so partial wiring cannot silently uncap anything, but it will block the
///      strategy. Step 14 consumes the shared PPS-oracle quorum: AUM validators/quorum are the
///      ones already registered on SuperGovernor.
///
///      SIGNER RUNBOOK (B2): a report that soft-fails a deviation check CONSUMES the AUM nonce;
///      a report that reverts (set drift: position exited/expired between signing and submission)
///      does NOT. Signers must re-read noncePerStrategy + the registry position set before every
///      re-sign.
contract DeployCrossChainSuperVaults is DeployV2Base {
    /*//////////////////////////////////////////////////////////////
                              CONSTANTS
    //////////////////////////////////////////////////////////////*/

    string internal constant REGISTRY_KEY = "CrossChainPositionRegistry";
    string internal constant ORACLE_KEY = "CrossChainAUMOracle";
    string internal constant CAP_GUARD_KEY = "CrossChainPositionCapGuard";
    string internal constant SCREENER_KEY = "CrossChainHooksRootScreener";

    /// @dev EIP-712 domain of the AUM oracle — part of the deterministic address; signers bind to it.
    string internal constant AUM_ORACLE_NAME = "SuperformCrossChainAUM";
    string internal constant AUM_ORACLE_VERSION = "1";

    bytes32 internal constant CROSS_CHAIN_POSITION_REGISTRY = keccak256("CROSS_CHAIN_POSITION_REGISTRY");
    bytes32 internal constant CROSS_CHAIN_AUM_ORACLE = keccak256("CROSS_CHAIN_AUM_ORACLE");
    bytes32 internal constant CROSS_CHAIN_CAP_GUARD = keccak256("CROSS_CHAIN_CAP_GUARD");

    /*//////////////////////////////////////////////////////////////
                            MAIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploy all four contracts and print the governance runbook
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Hub chain id to deploy on
    /// @param superGovernor The deployed SuperGovernor (source of roles + address book)
    function run(uint256 env, uint64 chainId, address superGovernor) external broadcast(env) {
        _deploy(env, chainId, superGovernor);
    }

    /// @notice Verify a deployment and report the live bootstrap state (address-book keys, roles)
    function runCheck(uint256 env, uint64 chainId, address superGovernor) external {
        _setBaseConfiguration(env, "");
        console2.log("====== CrossChain SuperVaults Deployment Check ======");
        console2.log("Chain ID:", chainId);
        console2.log("SuperGovernor:", superGovernor);

        address registry = _getContract(chainId, REGISTRY_KEY);
        address oracle = _getContract(chainId, ORACLE_KEY);
        address capGuard = _getContract(chainId, CAP_GUARD_KEY);
        address screener = _getContract(chainId, SCREENER_KEY);
        console2.log("Registry:", registry);
        console2.log("AUM oracle:", oracle);
        console2.log("Cap guard:", capGuard);
        console2.log("Screener:", screener);

        ISuperGovernor governor = ISuperGovernor(superGovernor);
        _checkKey(governor, "CROSS_CHAIN_POSITION_REGISTRY", CROSS_CHAIN_POSITION_REGISTRY, registry);
        _checkKey(governor, "CROSS_CHAIN_AUM_ORACLE", CROSS_CHAIN_AUM_ORACLE, oracle);
        _checkKey(governor, "CROSS_CHAIN_CAP_GUARD", CROSS_CHAIN_CAP_GUARD, capGuard);

        bool screenerIsGuardian = governor.hasRole(governor.GUARDIAN_ROLE(), screener);
        console2.log("Screener holds GUARDIAN_ROLE:", screenerIsGuardian);
        if (!screenerIsGuardian) console2.log("  [PENDING] grantRole(GUARDIAN_ROLE, screener) not landed");
        console2.log("====== Check Complete ======");
    }

    /*//////////////////////////////////////////////////////////////
                        GOVERNANCE CALLDATA PRINTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Calldata for authorizing one SuperVault*CapBridgeHook on the registry (step 5)
    function printHookAuthorization(address capHook) external pure {
        console2.log("-> registry.setBridgeHookAuthorization(capHook, true)  [GOVERNOR_ROLE]");
        console2.logBytes(abi.encodeCall(CrossChainPositionRegistry.setBridgeHookAuthorization, (capHook, true)));
    }

    /// @notice Calldata for banning one raw value-exit hook on the screener (step 6, K3)
    function printBanRawHook(address rawHook) external pure {
        console2.log("-> screener.setBannedHook(rawHook, true)  [GOVERNOR_ROLE]");
        console2.logBytes(abi.encodeCall(CrossChainHooksRootScreener.setBannedHook, (rawHook, true)));
    }

    /// @notice Calldata trio for one destination chain's transport policy (steps 7-9, B1/B4).
    /// @param eid LayerZero endpoint id for the chain; pass 0 when no Stargate route is configured
    function printDestinationPolicy(
        uint64 chainId,
        address adapter,
        address approveHook,
        address depositHook,
        uint32 eid
    )
        external
        pure
    {
        console2.log("-> capGuard.setDestinationAdapter(chainId, adapter, true)  [GOVERNOR_ROLE]");
        console2.logBytes(abi.encodeCall(CrossChainPositionCapGuard.setDestinationAdapter, (chainId, adapter, true)));
        console2.log("-> capGuard.setDestinationHooks(chainId, approveHook, depositHook)  [GOVERNOR_ROLE]");
        console2.logBytes(
            abi.encodeCall(CrossChainPositionCapGuard.setDestinationHooks, (chainId, approveHook, depositHook))
        );
        if (eid != 0) {
            console2.log("-> capGuard.setEidChainId(eid, chainId)  [GOVERNOR_ROLE] (B4)");
            console2.logBytes(abi.encodeCall(CrossChainPositionCapGuard.setEidChainId, (eid, chainId)));
        }
    }

    /// @notice Calldata pair for onboarding one strategy (steps 10-11); destination approvals and
    ///         cap limits (steps 12-13) are per-destination follow-ups, and the AUM oracle config
    ///         (step 14) is an ORACLE_MANAGER_ROLE action outside the Safe.
    function printStrategyOnboarding(address strategy, address registrar) external pure {
        console2.log("-> registry.setRegistrar(strategy, registrar)  [GOVERNOR_ROLE]");
        console2.logBytes(abi.encodeCall(CrossChainPositionRegistry.setRegistrar, (strategy, registrar)));
        console2.log("-> screener.setScreenedStrategy(strategy, true)  [GOVERNOR_ROLE] (K3)");
        console2.logBytes(abi.encodeCall(CrossChainHooksRootScreener.setScreenedStrategy, (strategy, true)));
    }

    /// @notice Calldata for clearing one reviewed strategy hooks root (R2-K3 default-deny): for a
    ///         SCREENED strategy every proposed root must have its full leaf set published and
    ///         governance-reviewed, then cleared here BEFORE the timelock elapses — otherwise
    ///         anyone can veto the strategy via `enforceProposalClearance`. This is the standing
    ///         operational rule for every root update of a cap-enabled strategy.
    function printRootClearance(address strategy, bytes32 root) external pure {
        console2.log("-> screener.setRootClearance(strategy, root, true)  [GOVERNOR_ROLE] (K3 default-deny)");
        console2.logBytes(abi.encodeCall(CrossChainHooksRootScreener.setRootClearance, (strategy, root, true)));
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _deploy(uint256 env, uint64 chainId, address superGovernor) internal {
        _setBaseConfiguration(env, "");

        console2.log("====== Deploying CrossChain SuperVaults periphery ======");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);
        console2.log("SuperGovernor:", superGovernor);
        console2.log("");

        require(superGovernor != address(0), "INVALID_SUPER_GOVERNOR");
        require(superGovernor.code.length > 0, "SUPER_GOVERNOR_NOT_DEPLOYED");
        // Sanity: it must actually expose the role surface every contract binds to.
        ISuperGovernor(superGovernor).GOVERNOR_ROLE();

        address registry = __deployContract(
            REGISTRY_KEY,
            chainId,
            __getSalt(REGISTRY_KEY),
            abi.encodePacked(type(CrossChainPositionRegistry).creationCode, abi.encode(superGovernor))
        );
        address oracle = __deployContract(
            ORACLE_KEY,
            chainId,
            __getSalt(ORACLE_KEY),
            abi.encodePacked(
                type(CrossChainAUMOracle).creationCode, abi.encode(superGovernor, AUM_ORACLE_NAME, AUM_ORACLE_VERSION)
            )
        );
        address capGuard = __deployContract(
            CAP_GUARD_KEY,
            chainId,
            __getSalt(CAP_GUARD_KEY),
            abi.encodePacked(type(CrossChainPositionCapGuard).creationCode, abi.encode(superGovernor))
        );
        address screener = __deployContract(
            SCREENER_KEY,
            chainId,
            __getSalt(SCREENER_KEY),
            abi.encodePacked(type(CrossChainHooksRootScreener).creationCode, abi.encode(superGovernor))
        );

        // Verify the immutable wiring of everything just deployed.
        require(
            address(CrossChainPositionRegistry(registry).SUPER_GOVERNOR()) == superGovernor,
            "REGISTRY_GOVERNOR_MISMATCH"
        );
        require(address(CrossChainAUMOracle(oracle).SUPER_GOVERNOR()) == superGovernor, "ORACLE_GOVERNOR_MISMATCH");
        require(
            address(CrossChainPositionCapGuard(capGuard).SUPER_GOVERNOR()) == superGovernor,
            "CAP_GUARD_GOVERNOR_MISMATCH"
        );
        require(
            address(CrossChainHooksRootScreener(screener).SUPER_GOVERNOR()) == superGovernor,
            "SCREENER_GOVERNOR_MISMATCH"
        );

        _printCoreWiring(superGovernor, registry, oracle, capGuard, screener);
    }

    /// @dev The four fixed governance txs (Safe): three address-book keys + the guardian grant.
    function _printCoreWiring(
        address superGovernor,
        address registry,
        address oracle,
        address capGuard,
        address screener
    )
        internal
        view
    {
        console2.log("");
        console2.log("====== Governance bootstrap (Safe txs on SuperGovernor", superGovernor, ") ======");

        console2.log("1) setAddress(CROSS_CHAIN_POSITION_REGISTRY, registry)  [SUPER_GOVERNOR_ROLE]");
        console2.logBytes(abi.encodeCall(ISuperGovernor.setAddress, (CROSS_CHAIN_POSITION_REGISTRY, registry)));
        console2.log("2) setAddress(CROSS_CHAIN_AUM_ORACLE, oracle)  [SUPER_GOVERNOR_ROLE]");
        console2.logBytes(abi.encodeCall(ISuperGovernor.setAddress, (CROSS_CHAIN_AUM_ORACLE, oracle)));
        console2.log("3) setAddress(CROSS_CHAIN_CAP_GUARD, capGuard)  [SUPER_GOVERNOR_ROLE]");
        console2.logBytes(abi.encodeCall(ISuperGovernor.setAddress, (CROSS_CHAIN_CAP_GUARD, capGuard)));

        bytes32 guardianRole = ISuperGovernor(superGovernor).GUARDIAN_ROLE();
        console2.log("4) grantRole(GUARDIAN_ROLE, screener)  [role admin] (K3 veto authority)");
        console2.logBytes(abi.encodeWithSignature("grantRole(bytes32,address)", guardianRole, screener));

        console2.log("");
        console2.log("Then: printHookAuthorization / printBanRawHook / printDestinationPolicy /");
        console2.log("printStrategyOnboarding for the parameterized steps (see contract NatSpec).");
    }

    function _checkKey(ISuperGovernor governor, string memory label, bytes32 key, address expected) internal view {
        address actual = governor.getAddress(key);
        console2.log(label, "->", actual);
        if (actual != expected) {
            console2.log("  [PENDING/MISMATCH] expected:", expected);
        }
    }
}
