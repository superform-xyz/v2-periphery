// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { DeploySuperVaultCounsel } from "../../../script/DeploySuperVaultCounsel.s.sol";
import { SuperVaultCounsel } from "../../../src/SuperVault/SuperVaultCounsel.sol";
import { MockCounselSuperGovernor } from "../SuperVaultCounsel.t.sol";

/// @dev Exposes the script's internal address prediction so the test can observe whether the
///      shared memory struct survives the call unchanged (the fleet path reuses it for _deploy),
///      and the fleet-config / validation internals so the JSON plumbing can be tested against an
///      in-memory fixture instead of the checked-in counsel-fleet.json.
contract DeployCounselHarness is DeploySuperVaultCounsel {
    string internal fixture;

    /// @notice Non-empty fixture replaces the checked-in counsel-fleet.json for this harness
    function setFleetFixture(string memory json) external {
        fixture = json;
    }

    function _fleetConfigJson() internal view override returns (string memory) {
        return bytes(fixture).length > 0 ? fixture : super._fleetConfigJson();
    }

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

    function validateParams(DeployParams memory p) external view {
        _validateParams(p);
    }

    function readFleetEntries(uint256 env, uint64 chainId) external view returns (FleetEntry[] memory) {
        return _readFleetEntries(env, chainId);
    }

    function fleetFromRegistry(uint256 env, address[] memory registry) external view returns (FleetEntry[] memory) {
        return _fleetFromRegistry(env, registry);
    }

    function strategyCeilings() external pure returns (uint256 perf, uint256 mgmt) {
        return (STRATEGY_MAX_PERFORMANCE_FEE_BPS, STRATEGY_MAX_MANAGEMENT_FEE_BPS);
    }

    function encodeConstructorArgs(DeployParams memory p, address vetoRegistry) external pure returns (bytes memory) {
        return _encodeConstructorArgs(p, vetoRegistry);
    }

    function verifyDeployment(DeployParams memory p, address counselAddr) external view {
        _verifyDeployment(p, counselAddr);
    }

    function timing() external pure returns (uint256 vetoWindow, uint256 expiry) {
        return (VETO_WINDOW, EXPIRY);
    }
}

/// @notice Review round 8 (P2-1): the fleet pre-check must not mutate DeployParams. A `view`
///         modifier does not protect memory arguments, and runAll passes the same struct to the
///         pre-check and then to _deploy. Plus (todos 001 / 004 / 005) the registry-fallback
///         struct aliasing, the per-strategy fee-cap plumbing, and the fee-cap validation.
contract DeploySuperVaultCounselScriptTest is Test {
    DeployCounselHarness internal harness;

    address internal operator = makeAddr("operator");
    address internal strategy = makeAddr("strategy");
    address internal strategyB = makeAddr("strategyB");
    address internal strategyC = makeAddr("strategyC");
    address internal guardianA = makeAddr("guardianA");
    address internal guardianB = makeAddr("guardianB");
    address internal superGovernor = makeAddr("superGovernor");
    address internal aggregator = makeAddr("aggregator");
    address internal executor = makeAddr("executor");

    uint256 internal constant DEFAULT_MIN_DEV = 1e15;
    uint256 internal constant DEFAULT_MAX_DEV = 99e16;
    // SuperVaultCounsel.STRATEGY_MAX_*_FEE_BPS (SuperVaultCounsel.t.sol asserts the contract side)
    uint256 internal constant PERF_CEILING = 5100;
    uint256 internal constant MGMT_CEILING = 10_000;

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
        p.minDev = DEFAULT_MIN_DEV;
        p.maxDev = DEFAULT_MAX_DEV;
        p.maxPerfFeeBps = PERF_CEILING;
        p.maxMgmtFeeBps = MGMT_CEILING;
        p.superGovernor = superGovernor;
        p.aggregator = aggregator;
        p.executor = executor;
        p.vetoRegistry = vetoRegistry;
        p.vetoGuardians = guardians;
    }

    /// @dev Params that pass every non-fee check (the strategy must have code: use this contract)
    function _validParams(uint256 env) internal view returns (DeploySuperVaultCounsel.DeployParams memory p) {
        p = _params(address(0), new address[](0));
        p.env = env;
        p.strategy = address(this);
    }

    /// @dev A minimal counsel-fleet.json with ceiling-equal prod fee defaults (5100 / 10_000, so the
    ///      no-tightening warning path stays covered; the checked-in file tightens to 3500 / 200) and
    ///      the given per-strategy entries under chain 8453 (staging section present but empty)
    function _fixture(string memory entries8453) internal view returns (string memory) {
        string memory defaults = string(
            abi.encodePacked(
                '{"operator":"',
                vm.toString(operator),
                '","vetoRegistry":"0x0000000000000000000000000000000000000000","vetoGuardians":[],',
                '"minDeviationThreshold":"1000000000000000","maxDeviationThreshold":"990000000000000000",',
                '"maxPerformanceFeeBps":"5100","maxManagementFeeBps":"10000"}'
            )
        );
        return string(
            abi.encodePacked(
                '{"prod":{"defaults":',
                defaults,
                ',"strategies":{"8453":[',
                entries8453,
                ']}},"staging":{"defaults":',
                defaults,
                ',"strategies":{"8453":[]}}}'
            )
        );
    }

    function _entry(address s, string memory extraFields) internal pure returns (string memory) {
        return string(abi.encodePacked('{"strategy":"', vm.toString(s), '"', extraFields, "}"));
    }

    /*//////////////////////////////////////////////////////////////
                    PRE-CHECK MUST NOT MUTATE PARAMS
    //////////////////////////////////////////////////////////////*/

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

    /*//////////////////////////////////////////////////////////////
                 REGISTRY FALLBACK (todo 001: struct aliasing)
    //////////////////////////////////////////////////////////////*/

    /// Pre-fix `entries[i] = d` aliased every element to the one defaults struct, so every entry
    /// reported the LAST registry strategy. Each entry must own its strategy, with the defaults
    /// otherwise identical and the zero-cap opt-in never inherited.
    function test_FleetFromRegistry_EachEntryHasOwnStrategy() public {
        harness.setFleetFixture(_fixture(""));
        address[] memory registry = new address[](3);
        registry[0] = strategy;
        registry[1] = strategyB;
        registry[2] = strategyC;

        DeploySuperVaultCounsel.FleetEntry[] memory entries = harness.fleetFromRegistry(0, registry);

        assertEq(entries.length, 3);
        for (uint256 i = 0; i < entries.length; i++) {
            assertEq(entries[i].strategy, registry[i], "entry aliased to another strategy");
            assertEq(entries[i].operator, operator);
            assertEq(entries[i].vetoRegistry, address(0));
            assertEq(entries[i].vetoGuardians.length, 0);
            assertEq(entries[i].minDev, DEFAULT_MIN_DEV);
            assertEq(entries[i].maxDev, DEFAULT_MAX_DEV);
            assertEq(entries[i].maxPerfFeeBps, PERF_CEILING);
            assertEq(entries[i].maxMgmtFeeBps, MGMT_CEILING);
            assertFalse(entries[i].allowZeroFeeCap, "zero-cap opt-in must never come from defaults");
        }
        assertTrue(entries[0].strategy != entries[2].strategy);
    }

    /// Same with the checked-in counsel-fleet.json (no fixture): proves the real file parses and
    /// the fallback still yields distinct strategies from it
    function test_FleetFromRegistry_CheckedInConfig() public view {
        address[] memory registry = new address[](3);
        registry[0] = strategy;
        registry[1] = strategyB;
        registry[2] = strategyC;
        DeploySuperVaultCounsel.FleetEntry[] memory entries = harness.fleetFromRegistry(2, registry);
        assertEq(entries.length, 3);
        assertEq(entries[0].strategy, strategy);
        assertEq(entries[1].strategy, strategyB);
        assertEq(entries[2].strategy, strategyC);
        // checked-in staging fee defaults are the agreed 3500 / 200 (below the ceilings, not zero)
        for (uint256 i; i < entries.length; ++i) {
            assertEq(entries[i].maxPerfFeeBps, 3500);
            assertEq(entries[i].maxMgmtFeeBps, 200);
            assertFalse(entries[i].allowZeroFeeCap);
        }
        // and prod (env 0) carries the same tightened defaults - a drift back to 5100 / 10_000 fails here
        DeploySuperVaultCounsel.FleetEntry[] memory prodEntries = harness.fleetFromRegistry(0, registry);
        assertEq(prodEntries.length, 3);
        for (uint256 i; i < prodEntries.length; ++i) {
            assertEq(prodEntries[i].maxPerfFeeBps, 3500);
            assertEq(prodEntries[i].maxMgmtFeeBps, 200);
            assertFalse(prodEntries[i].allowZeroFeeCap);
        }
    }

    /*//////////////////////////////////////////////////////////////
              FLEET JSON FEE-CAP PLUMBING (todo 005)
    //////////////////////////////////////////////////////////////*/

    /// Per-strategy maxPerformanceFeeBps / maxManagementFeeBps / allowZeroFeeCap overrides win;
    /// omitted fields fall back to the environment defaults (and allowZeroFeeCap to false)
    function test_FleetEntries_FeeCapOverridesAndDefaults() public {
        harness.setFleetFixture(
            _fixture(
                string(
                    abi.encodePacked(
                        _entry(
                            strategy,
                            ',"maxPerformanceFeeBps":"2000","maxManagementFeeBps":"500","allowZeroFeeCap":true'
                        ),
                        ",",
                        _entry(strategyB, ""),
                        ",",
                        _entry(strategyC, ',"maxPerformanceFeeBps":"0"')
                    )
                )
            )
        );

        DeploySuperVaultCounsel.FleetEntry[] memory entries = harness.readFleetEntries(0, 8453);

        assertEq(entries.length, 3);
        // full override
        assertEq(entries[0].strategy, strategy);
        assertEq(entries[0].maxPerfFeeBps, 2000);
        assertEq(entries[0].maxMgmtFeeBps, 500);
        assertTrue(entries[0].allowZeroFeeCap);
        // defaults fallback
        assertEq(entries[1].strategy, strategyB);
        assertEq(entries[1].maxPerfFeeBps, PERF_CEILING);
        assertEq(entries[1].maxMgmtFeeBps, MGMT_CEILING);
        assertFalse(entries[1].allowZeroFeeCap);
        assertEq(entries[1].operator, operator);
        assertEq(entries[1].minDev, DEFAULT_MIN_DEV);
        assertEq(entries[1].maxDev, DEFAULT_MAX_DEV);
        // partial override: an explicit zero is kept (not treated as "omitted")
        assertEq(entries[2].strategy, strategyC);
        assertEq(entries[2].maxPerfFeeBps, 0);
        assertEq(entries[2].maxMgmtFeeBps, MGMT_CEILING);
        assertFalse(entries[2].allowZeroFeeCap);
    }

    /// An over-ceiling value in the JSON parses fine and is rejected by _validateParams, which is
    /// where runOne/runAll feed it (readable reason before CREATE2 simulation)
    function test_FleetEntries_OverCeilingRejectedAtValidation() public {
        harness.setFleetFixture(_fixture(_entry(strategy, ',"maxPerformanceFeeBps":"5101"')));
        DeploySuperVaultCounsel.FleetEntry[] memory entries = harness.readFleetEntries(0, 8453);
        assertEq(entries[0].maxPerfFeeBps, PERF_CEILING + 1);

        DeploySuperVaultCounsel.DeployParams memory p = _validParams(0);
        p.maxPerfFeeBps = entries[0].maxPerfFeeBps;
        p.maxMgmtFeeBps = entries[0].maxMgmtFeeBps;
        p.allowZeroFeeCap = entries[0].allowZeroFeeCap;
        vm.expectRevert(bytes("PERF_FEE_CAP_ABOVE_STRATEGY_CEILING"));
        harness.validateParams(p);
    }

    /// A prod entry with an explicit "0" cap and no allowZeroFeeCap reaches _validateParams and is
    /// rejected there (todo 004); the same entry with the flag passes
    function test_FleetEntries_ProdZeroCapNeedsOptIn() public {
        harness.setFleetFixture(
            _fixture(
                string(
                    abi.encodePacked(
                        _entry(strategy, ',"maxManagementFeeBps":"0"'),
                        ",",
                        _entry(strategyB, ',"maxManagementFeeBps":"0","allowZeroFeeCap":true')
                    )
                )
            )
        );
        DeploySuperVaultCounsel.FleetEntry[] memory entries = harness.readFleetEntries(0, 8453);

        DeploySuperVaultCounsel.DeployParams memory p = _validParams(0);
        p.maxPerfFeeBps = entries[0].maxPerfFeeBps;
        p.maxMgmtFeeBps = entries[0].maxMgmtFeeBps;
        p.allowZeroFeeCap = entries[0].allowZeroFeeCap;
        vm.expectRevert(bytes("ZERO_FEE_CAP_REQUIRES_OPT_IN"));
        harness.validateParams(p);

        p.maxPerfFeeBps = entries[1].maxPerfFeeBps;
        p.maxMgmtFeeBps = entries[1].maxMgmtFeeBps;
        p.allowZeroFeeCap = entries[1].allowZeroFeeCap;
        harness.validateParams(p); // opt-in present: no revert
    }

    /*//////////////////////////////////////////////////////////////
                _validateParams FEE-CAP CHECKS (todos 004 / 005)
    //////////////////////////////////////////////////////////////*/

    function test_ValidateParams_CeilingValuesPass() public view {
        harness.validateParams(_validParams(0)); // 5100 / 10000 in prod: warns, does not revert
        harness.validateParams(_validParams(2));
    }

    function test_ValidateParams_RevertIf_PerfCapAboveCeiling() public {
        DeploySuperVaultCounsel.DeployParams memory p = _validParams(0);
        p.maxPerfFeeBps = 5101;
        vm.expectRevert(bytes("PERF_FEE_CAP_ABOVE_STRATEGY_CEILING"));
        harness.validateParams(p);
    }

    function test_ValidateParams_RevertIf_MgmtCapAboveCeiling() public {
        DeploySuperVaultCounsel.DeployParams memory p = _validParams(0);
        p.maxMgmtFeeBps = 10_001;
        vm.expectRevert(bytes("MGMT_FEE_CAP_ABOVE_STRATEGY_CEILING"));
        harness.validateParams(p);
    }

    /// The script mirrors the Counsel's STRATEGY_MAX_*_FEE_BPS (SuperVaultCounsel.t.sol pins the
    /// contract side to the same literals; _verifyDeployment re-checks the mirror post-deploy)
    function test_ValidateParams_CeilingsMatchCounsel() public view {
        (uint256 perf, uint256 mgmt) = harness.strategyCeilings();
        assertEq(perf, PERF_CEILING);
        assertEq(mgmt, MGMT_CEILING);
    }

    function test_ValidateParams_RevertIf_ProdZeroPerfCapWithoutOptIn() public {
        DeploySuperVaultCounsel.DeployParams memory p = _validParams(0);
        p.maxPerfFeeBps = 0;
        vm.expectRevert(bytes("ZERO_FEE_CAP_REQUIRES_OPT_IN"));
        harness.validateParams(p);
    }

    function test_ValidateParams_RevertIf_ProdZeroMgmtCapWithoutOptIn() public {
        DeploySuperVaultCounsel.DeployParams memory p = _validParams(0);
        p.maxMgmtFeeBps = 0;
        vm.expectRevert(bytes("ZERO_FEE_CAP_REQUIRES_OPT_IN"));
        harness.validateParams(p);
    }

    function test_ValidateParams_ProdZeroCapWithOptInPasses() public view {
        DeploySuperVaultCounsel.DeployParams memory p = _validParams(0);
        p.maxPerfFeeBps = 0;
        p.maxMgmtFeeBps = 0;
        p.allowZeroFeeCap = true;
        harness.validateParams(p);
    }

    /// Outside prod a zero cap only warns (staging/vnet fleets are disposable)
    function test_ValidateParams_NonProdZeroCapNeedsNoOptIn() public view {
        DeploySuperVaultCounsel.DeployParams memory p = _validParams(2);
        p.maxPerfFeeBps = 0;
        p.maxMgmtFeeBps = 0;
        harness.validateParams(p);

        p = _validParams(1);
        p.maxMgmtFeeBps = 0;
        harness.validateParams(p);
    }

    /*//////////////////////////////////////////////////////////////
            CONSTRUCTOR-ARG ENCODING, ADDRESS, POST-DEPLOY VERIFY
    //////////////////////////////////////////////////////////////*/

    /// @notice The caps are encoded last, in constructor declaration order, after the deviation bounds
    function test_EncodeConstructorArgs_IncludesFeeCapsInDeclarationOrder() public view {
        DeploySuperVaultCounsel.DeployParams memory p = _params(address(0), new address[](0));
        p.maxPerfFeeBps = 3000;
        p.maxMgmtFeeBps = 25;
        bytes memory args = harness.encodeConstructorArgs(p, superGovernor);
        (,,,,,, uint256 vetoWindow, uint256 expiry, uint256 minDev, uint256 maxDev, uint256 perfCap, uint256 mgmtCap) = abi.decode(
            args,
            (address, address, address, address, address, address, uint256, uint256, uint256, uint256, uint256, uint256)
        );
        (uint256 expectedWindow, uint256 expectedExpiry) = harness.timing();
        assertEq(vetoWindow, expectedWindow);
        assertEq(expiry, expectedExpiry);
        assertEq(minDev, DEFAULT_MIN_DEV);
        assertEq(maxDev, DEFAULT_MAX_DEV);
        assertEq(perfCap, 3000);
        assertEq(mgmtCap, 25);
    }

    /// @notice Immutable caps participate in the CREATE2 address: two Counsels for the same
    ///         strategy with different caps land at different addresses (and equal caps are stable)
    function test_FeeCapsParticipateInCounselAddress() public view {
        DeploySuperVaultCounsel.DeployParams memory a = _params(address(0), new address[](0));
        DeploySuperVaultCounsel.DeployParams memory b = _params(address(0), new address[](0));
        (address addrA,) = harness.computeTwice(a);
        b.maxPerfFeeBps = 3000;
        (address addrB,) = harness.computeTwice(b);
        DeploySuperVaultCounsel.DeployParams memory c = _params(address(0), new address[](0));
        c.maxMgmtFeeBps = 0;
        (address addrC,) = harness.computeTwice(c);
        assertTrue(addrA != addrB, "perf cap must change the address");
        assertTrue(addrA != addrC, "mgmt cap must change the address");
        assertTrue(addrB != addrC);
        (address again,) = harness.computeTwice(a);
        assertEq(again, addrA);
    }

    /// @dev Deploys a real Counsel with the script's timing and the given caps against a mock
    ///      governor (the only counterparty the constructor dereferences)
    function _deployRealCounsel(DeploySuperVaultCounsel.DeployParams memory p) internal returns (address) {
        (uint256 vetoWindow, uint256 expiry) = harness.timing();
        return address(
            new SuperVaultCounsel(
                p.operator,
                p.superGovernor,
                p.vetoRegistry,
                p.aggregator,
                p.strategy,
                p.executor,
                vetoWindow,
                expiry,
                p.minDev,
                p.maxDev,
                p.maxPerfFeeBps,
                p.maxMgmtFeeBps
            )
        );
    }

    /// @notice The post-deploy verification accepts a Counsel whose immutables match, and rejects
    ///         a fee-cap mismatch with the named error (the one check todo 005 left uncovered)
    function test_VerifyDeployment_FeeCapMismatchIsNamed() public {
        DeploySuperVaultCounsel.DeployParams memory p = _params(address(0), new address[](0));
        p.superGovernor = address(new MockCounselSuperGovernor());
        p.maxPerfFeeBps = 3000;
        p.maxMgmtFeeBps = 500;
        address counsel = _deployRealCounsel(p);
        harness.verifyDeployment(p, counsel); // exact match passes

        // memory structs alias on assignment, so each variant is built fresh (todo 001 lesson)
        DeploySuperVaultCounsel.DeployParams memory wrongPerf = _params(address(0), new address[](0));
        wrongPerf.superGovernor = p.superGovernor;
        wrongPerf.maxPerfFeeBps = 3001;
        wrongPerf.maxMgmtFeeBps = 500;
        vm.expectRevert(bytes("MAX_PERF_FEE_MISMATCH"));
        harness.verifyDeployment(wrongPerf, counsel);

        DeploySuperVaultCounsel.DeployParams memory wrongMgmt = _params(address(0), new address[](0));
        wrongMgmt.superGovernor = p.superGovernor;
        wrongMgmt.maxPerfFeeBps = 3000;
        wrongMgmt.maxMgmtFeeBps = 499;
        vm.expectRevert(bytes("MAX_MGMT_FEE_MISMATCH"));
        harness.verifyDeployment(wrongMgmt, counsel);

        // the untouched original still verifies: the variants did not leak into it
        harness.verifyDeployment(p, counsel);
    }

    /// @notice Verification reads the chain, not the config: a Counsel deployed at the ceilings is
    ///         rejected when the config has since been tightened (so a stale deployment cannot be
    ///         mistaken for the capped one)
    function test_VerifyDeployment_RejectsStaleCeilingDeploymentAgainstTightenedConfig() public {
        DeploySuperVaultCounsel.DeployParams memory deployed = _params(address(0), new address[](0));
        deployed.superGovernor = address(new MockCounselSuperGovernor());
        address counsel = _deployRealCounsel(deployed); // ceilings 5100 / 10_000
        DeploySuperVaultCounsel.DeployParams memory tightened = _params(address(0), new address[](0));
        tightened.superGovernor = deployed.superGovernor;
        tightened.maxPerfFeeBps = 3000;
        vm.expectRevert(bytes("MAX_PERF_FEE_MISMATCH"));
        harness.verifyDeployment(tightened, counsel);
    }
}
