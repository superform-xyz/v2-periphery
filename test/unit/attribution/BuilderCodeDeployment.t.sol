// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { DeploySuperBuilderCodeRegistry } from "../../../script/DeploySuperBuilderCodeRegistry.s.sol";
import { SuperBuilderCodeRegistry } from "../../../src/attribution/SuperBuilderCodeRegistry.sol";

contract BuilderCodeDeploymentHarness is DeploySuperBuilderCodeRegistry {
    function validateBytecode(bytes memory bytecode) external {
        _validateBytecode(bytecode);
    }

    function verifyRegistry(address registry) external view {
        _verifyRegistry(registry);
    }

    function governance() external pure returns (address) {
        return GOVERNOR;
    }
}

contract BuilderCodeDeploymentTest is Test {
    BuilderCodeDeploymentHarness internal script_;

    function setUp() public {
        script_ = new BuilderCodeDeploymentHarness();
    }

    function testFuzz_DeploymentRejectsEveryOtherChain(uint64 chainId) public {
        vm.assume(chainId != 8453);
        vm.chainId(chainId);
        vm.expectRevert(DeploySuperBuilderCodeRegistry.WRONG_CHAIN.selector);
        script_.run(false);
    }

    function test_DeploymentRequiresFactoryCode() public {
        vm.chainId(8453);
        vm.etch(0x4e59b44847b379578588920cA78FbF26c0B4956C, hex"");
        vm.expectRevert(DeploySuperBuilderCodeRegistry.DEPENDENCY_NOT_DEPLOYED.selector);
        script_.run(true);
    }

    function test_OnlyExactCompiledCreationBytecodeIsAccepted() public {
        bytes memory bytecode = type(SuperBuilderCodeRegistry).creationCode;
        script_.validateBytecode(bytecode);
        bytecode[0] = bytes1(uint8(bytecode[0]) ^ 1);
        vm.expectRevert(DeploySuperBuilderCodeRegistry.LOCKED_BYTECODE_MISMATCH.selector);
        script_.validateBytecode(bytecode);
        vm.expectRevert(DeploySuperBuilderCodeRegistry.LOCKED_BYTECODE_MISMATCH.selector);
        script_.validateBytecode("");
    }

    function test_VerificationChecksRuntimeAndGovernance() public {
        address governance = script_.governance();
        SuperBuilderCodeRegistry registry = new SuperBuilderCodeRegistry(governance);
        script_.verifyRegistry(address(registry));
        assertFalse(registry.hasRole(bytes32(0), address(this)));
        vm.prank(governance);
        registry.registerCode("first_code", keccak256("partner"), address(this), "");
        assertEq(registry.payoutAddress("first_code"), address(this));

        vm.expectRevert(DeploySuperBuilderCodeRegistry.RUNTIME_BYTECODE_MISMATCH.selector);
        script_.verifyRegistry(address(this));
        SuperBuilderCodeRegistry wrongAdmin = new SuperBuilderCodeRegistry(address(this));
        vm.expectRevert(DeploySuperBuilderCodeRegistry.GOVERNANCE_MISMATCH.selector);
        script_.verifyRegistry(address(wrongAdmin));
    }

    function test_FullCheckAndIdempotentDeploymentNeverWriteProductionManifest() public {
        vm.chainId(8453);
        vm.etch(
            0x4e59b44847b379578588920cA78FbF26c0B4956C,
            hex"7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b8082525050506014600cf3"
        );
        assertEq(script_.governance().code.length, 0, "governor may be an EOA or undeployed address");
        string memory manifestPath = "script/output/prod/8453/Base-latest.json";
        bytes32 manifestBefore = keccak256(bytes(vm.readFile(manifestPath)));
        address predicted = script_.run(true);
        assertTrue(predicted != 0xAa47CcbbD7074e33F89fE4ee98a6eAc304762888, "must differ from original registry");
        assertTrue(predicted != 0x5E02efd9443CEEd45af408E45bbB5e28c35A3cE0, "new admin requires a new address");
        assertEq(predicted.code.length, 0, "check must not deploy");
        assertEq(script_.run(false), predicted);
        script_.verifyRegistry(predicted);
        assertFalse(SuperBuilderCodeRegistry(predicted).hasRole(bytes32(0), address(this)));
        assertFalse(SuperBuilderCodeRegistry(predicted).hasRole(bytes32(0), 0x4e59b44847b379578588920cA78FbF26c0B4956C));
        assertEq(script_.run(false), predicted, "repeat deployment must be idempotent");
        assertEq(keccak256(bytes(vm.readFile(manifestPath))), manifestBefore, "simulation must not write manifests");
    }
}
