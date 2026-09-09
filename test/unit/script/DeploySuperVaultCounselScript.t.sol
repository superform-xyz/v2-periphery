// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { DeploySuperVaultCounsel } from "../../../script/DeploySuperVaultCounsel.s.sol";

/// @dev Exposes the script's internal address prediction so the test can observe whether the
///      shared memory struct survives the call unchanged (the fleet path reuses it for _deploy).
contract DeployCounselHarness is DeploySuperVaultCounsel {
    /// @notice Mirrors runAll: predict (as the already-deployed pre-check does), then resolve the
    ///         veto authority again (as _deploy does through _resolveOrDeployVetoRegistry)
    function precheckThenResolve(DeployParams memory p)
        external
        view
        returns (address counselPredicted, address vetoRegistryAfterPrecheck, address registryForDeploy)
    {
        counselPredicted = _computeAddress(p);
        vetoRegistryAfterPrecheck = p.vetoRegistry;
        registryForDeploy = _predictVetoRegistry(p); // reverts AMBIGUOUS_* if the pre-check leaked
    }

    function computeTwice(DeployParams memory p) external view returns (address first, address second) {
        first = _computeAddress(p);
        second = _computeAddress(p);
    }
}

/// @notice Review round 8 (P2-1): the fleet pre-check must not mutate DeployParams. A `view`
///         modifier does not protect memory arguments, and runAll passes the same struct to the
///         pre-check and then to _deploy.
contract DeploySuperVaultCounselScriptTest is Test {
    DeployCounselHarness internal harness;

    address internal operator = makeAddr("operator");
    address internal strategy = makeAddr("strategy");
    address internal guardianA = makeAddr("guardianA");
    address internal guardianB = makeAddr("guardianB");
    address internal superGovernor = makeAddr("superGovernor");
    address internal aggregator = makeAddr("aggregator");
    address internal executor = makeAddr("executor");

    function setUp() public {
        harness = new DeployCounselHarness();
    }

    function _params(
        address vetoRegistry,
        address[] memory guardians
    )
        internal
        view
        returns (DeploySuperVaultCounsel.DeployParams memory p)
    {
        p.env = 0; // prod artifacts: script/locked-bytecode
        p.chainId = 8453;
        p.operator = operator;
        p.strategy = strategy;
        p.minDev = 1e15;
        p.maxDev = 99e16;
        p.superGovernor = superGovernor;
        p.aggregator = aggregator;
        p.executor = executor;
        p.vetoRegistry = vetoRegistry;
        p.vetoGuardians = guardians;
    }

    /// The checked-in NVDA / TestNVDA-RH shape: guardians set, registry zero. Before the fix the
    /// pre-check wrote the predicted registry into p.vetoRegistry and _deploy then rejected the
    /// entry as "guardians AND registry set".
    function test_Precheck_DoesNotMutateParams_GuardianBatch() public view {
        address[] memory guardians = new address[](1);
        guardians[0] = guardianA;
        DeploySuperVaultCounsel.DeployParams memory p = _params(address(0), guardians);

        (address counselPredicted, address vetoRegistryAfter, address registryForDeploy) =
            harness.precheckThenResolve(p);

        assertEq(vetoRegistryAfter, address(0), "pre-check leaked the predicted registry into params");
        assertTrue(registryForDeploy != address(0), "guardian batch predicts a per-strategy registry");
        assertTrue(counselPredicted != address(0));
    }

    /// Prediction is idempotent on the same struct (pre-fix the second call reverted AMBIGUOUS_*)
    function test_Precheck_IsIdempotent() public view {
        address[] memory guardians = new address[](2);
        guardians[0] = guardianA;
        guardians[1] = guardianB;
        (address first, address second) = harness.computeTwice(_params(address(0), guardians));
        assertEq(first, second);
    }

    /// Custom-registry and SuperGovernor-fallback shapes are unaffected either way
    function test_Precheck_CustomRegistryAndFallbackUnchanged() public view {
        address[] memory none = new address[](0);
        // a contract address stands in for a deployed custom registry
        (, address afterCustom, address resolvedCustom) = harness.precheckThenResolve(_params(address(harness), none));
        assertEq(afterCustom, address(harness));
        assertEq(resolvedCustom, address(harness));

        (, address afterFallback, address resolvedFallback) = harness.precheckThenResolve(_params(address(0), none));
        assertEq(afterFallback, address(0));
        assertEq(resolvedFallback, address(0));
    }

    /// The guardian-batch and fallback shapes must land at DIFFERENT Counsel addresses (the
    /// registry participates in CREATE2), which is why the pre-check has to predict it at all
    function test_Precheck_RegistryParticipatesInAddress() public view {
        address[] memory guardians = new address[](1);
        guardians[0] = guardianA;
        address[] memory none = new address[](0);
        (address withGuardians,,) = harness.precheckThenResolve(_params(address(0), guardians));
        (address fallbackAddr,,) = harness.precheckThenResolve(_params(address(0), none));
        assertTrue(withGuardians != fallbackAddr);
    }
}
