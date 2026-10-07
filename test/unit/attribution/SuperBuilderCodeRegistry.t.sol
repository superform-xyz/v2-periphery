// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { ICodeRegistry } from "../../../src/interfaces/ICodeRegistry.sol";
import { ISuperBuilderCodeRegistry } from "../../../src/interfaces/ISuperBuilderCodeRegistry.sol";
import { SuperBuilderCodeRegistry } from "../../../src/attribution/SuperBuilderCodeRegistry.sol";
import { BuilderCodeFixtures } from "../../utils/BuilderCodeFixtures.sol";

contract SuperBuilderCodeRegistryTest is Test {
    SuperBuilderCodeRegistry internal registry;
    address internal governance = makeAddr("governance");
    address internal otherPayout = makeAddr("otherPayout");
    address internal payout = makeAddr("payout");
    bytes32 internal constant PARTNER = keccak256("partner identity");
    bytes32 internal constant CODE_HASH = keccak256("partner_1");
    string internal constant URI = "ipfs://partner-metadata";

    function setUp() public {
        registry = new SuperBuilderCodeRegistry(governance);
    }

    function test_ConstructorGrantsOnlyGovernanceAdmin() public view {
        assertTrue(registry.hasRole(bytes32(0), governance));
        assertFalse(registry.hasRole(bytes32(0), address(this)));
        assertFalse(registry.hasRole(bytes32(0), payout));
        assertEq(registry.getRoleAdmin(bytes32(0)), bytes32(0));
    }

    function test_ConstructorRejectsZeroGovernance() public {
        vm.expectRevert(ISuperBuilderCodeRegistry.ZERO_ADDRESS.selector);
        new SuperBuilderCodeRegistry(address(0));
    }

    function test_RegistrationAndStandardReadInterface() public {
        vm.expectEmit(true, true, false, true, address(registry));
        emit ISuperBuilderCodeRegistry.CodeRegistered(CODE_HASH, PARTNER, "partner_1", payout, URI);
        _register();
        ICodeRegistry standard = ICodeRegistry(address(registry));
        assertTrue(standard.isValidCode("partner_1"));
        assertTrue(standard.isRegistered("partner_1"));
        assertEq(standard.payoutAddress("partner_1"), payout);
        assertEq(standard.codeURI("partner_1"), URI);
        assertEq(registry.partnerId("partner_1"), PARTNER);
    }

    function test_UnknownReadsAreEmptyButFormatValidityIsIndependent() public view {
        assertTrue(registry.isValidCode("unknown_1"));
        assertFalse(registry.isRegistered("unknown_1"));
        assertEq(registry.partnerId("unknown_1"), bytes32(0));
        assertEq(registry.payoutAddress("unknown_1"), address(0));
        assertEq(registry.codeURI("unknown_1"), "");
        assertFalse(registry.isValidCode(""));
        assertFalse(registry.isRegistered(""));
        assertEq(registry.payoutAddress(""), address(0));
        assertEq(registry.codeURI("INVALID,CODE"), "");
    }

    function test_SharedSchemaOneFixtureMatchesExecutionTests() public view {
        string memory fixtures = vm.readFile("test/fixtures/builder-codes.json");
        assertEq(vm.parseJsonBytes(fixtures, "$[0].suffix"), BuilderCodeFixtures.suffix());
        assertEq(vm.parseJsonUint(fixtures, "$[0].registry.ChainID"), 8453);
        assertTrue(registry.isValidCode(vm.parseJsonString(fixtures, "$[0].code")));
    }

    function test_CodeBoundariesAndNoNormalization() public {
        string memory maximum = "abcdefghijklmnopqrstuvwxyz01234_";
        assertEq(bytes(maximum).length, 32);
        assertTrue(registry.isValidCode(maximum));
        assertFalse(registry.isValidCode(string.concat(maximum, "a")));
        assertTrue(registry.isValidCode("_"));
        assertTrue(registry.isValidCode("0"));
        assertTrue(registry.isValidCode("a"));
        assertFalse(registry.isValidCode("Partner_1"));
        assertFalse(registry.isValidCode(" partner_1"));
        assertFalse(registry.isValidCode("partner_1 "));
        assertFalse(registry.isValidCode("partner,1"));
        assertFalse(registry.isValidCode("partner-1"));
        assertFalse(registry.isValidCode(unicode"partnér"));
        assertFalse(registry.isValidCode(string(hex"706172746e657200")));
        vm.prank(governance);
        registry.registerCode(maximum, PARTNER, payout, "");
        _register();
        assertFalse(registry.isRegistered("Partner_1"));
    }

    function test_AllSingleByteCharacters() public view {
        // An explicit alphabet checks every byte, including NUL, comma, whitespace and high bytes.
        bytes memory alphabet = "abcdefghijklmnopqrstuvwxyz0123456789_";
        for (uint256 c; c < 256; ++c) {
            bool accepted;
            for (uint256 j; j < alphabet.length; ++j) {
                if (uint8(alphabet[j]) == c) accepted = true;
            }
            assertEq(registry.isValidCode(string(abi.encodePacked(uint8(c)))), accepted);
        }
    }

    function testFuzz_InvalidFormatCannotRegister(string memory code) public {
        vm.assume(!registry.isValidCode(code));
        vm.prank(governance);
        vm.expectRevert(ISuperBuilderCodeRegistry.INVALID_CODE.selector);
        registry.registerCode(code, PARTNER, payout, "");
        assertFalse(registry.isRegistered(code));
    }

    function test_RejectsInvalidRegistrationValues() public {
        vm.startPrank(governance);
        vm.expectRevert(ISuperBuilderCodeRegistry.INVALID_PARTNER_ID.selector);
        registry.registerCode("partner_1", bytes32(0), payout, URI);
        vm.expectRevert(ISuperBuilderCodeRegistry.ZERO_ADDRESS.selector);
        registry.registerCode("partner_1", PARTNER, address(0), URI);
        vm.expectRevert(ISuperBuilderCodeRegistry.URI_TOO_LONG.selector);
        registry.registerCode("partner_1", PARTNER, payout, string(new bytes(2049)));
        vm.stopPrank();
        assertFalse(registry.isRegistered("partner_1"));
    }

    function test_DuplicateCannotOverwriteEvenForSamePartner() public {
        _register();
        vm.startPrank(governance);
        vm.expectRevert(ISuperBuilderCodeRegistry.CODE_ALREADY_REGISTERED.selector);
        registry.registerCode("partner_1", PARTNER, payout, URI);
        vm.expectRevert(ISuperBuilderCodeRegistry.CODE_ALREADY_REGISTERED.selector);
        registry.registerCode("partner_1", keccak256("other"), otherPayout, "replacement");
        vm.stopPrank();
        assertEq(registry.partnerId("partner_1"), PARTNER);
        assertEq(registry.payoutAddress("partner_1"), payout);
        assertEq(registry.codeURI("partner_1"), URI);
    }

    function test_MultipleCodesForOnePartner() public {
        _register();
        vm.prank(governance);
        registry.registerCode("partner_2", PARTNER, otherPayout, "");
        assertEq(registry.partnerId("partner_2"), PARTNER);
        assertEq(registry.payoutAddress("partner_1"), payout);
        assertEq(registry.payoutAddress("partner_2"), otherPayout);
    }

    function test_PayoutUpdateEmitsHistoryAndPreservesIdentity() public {
        _register();
        vm.expectEmit(true, false, false, true, address(registry));
        emit ISuperBuilderCodeRegistry.PayoutAddressUpdated(CODE_HASH, payout, otherPayout);
        vm.prank(payout);
        registry.setPayoutAddress("partner_1", otherPayout);
        assertEq(registry.payoutAddress("partner_1"), otherPayout);
        assertEq(registry.partnerId("partner_1"), PARTNER);
        assertEq(registry.codeURI("partner_1"), URI);
    }

    function test_URIUpdateEmitsHistoryAndMayBeCleared() public {
        _register();
        vm.expectEmit(true, false, false, true, address(registry));
        emit ISuperBuilderCodeRegistry.CodeURIUpdated(CODE_HASH, URI, "");
        vm.prank(payout);
        registry.setCodeURI("partner_1", "");
        assertEq(registry.codeURI("partner_1"), "");
        assertEq(registry.partnerId("partner_1"), PARTNER);
        assertEq(registry.payoutAddress("partner_1"), payout);
    }

    function test_UnchangedMetadataEmitsNoEvents() public {
        _register();
        vm.recordLogs();
        vm.startPrank(payout);
        registry.setPayoutAddress("partner_1", payout);
        registry.setCodeURI("partner_1", URI);
        vm.stopPrank();
        assertEq(vm.getRecordedLogs().length, 0);
    }

    function test_URIByteLimitAtRegistrationAndUpdate() public {
        // UTF-8 length, rather than character count, determines the limit.
        string memory atLimit = string(new bytes(2048));
        vm.prank(governance);
        registry.registerCode("partner_1", PARTNER, payout, atLimit);
        assertEq(bytes(registry.codeURI("partner_1")).length, 2048);
        vm.startPrank(payout);
        registry.setCodeURI("partner_1", "");
        registry.setCodeURI("partner_1", atLimit);
        vm.expectRevert(ISuperBuilderCodeRegistry.URI_TOO_LONG.selector);
        registry.setCodeURI("partner_1", string.concat(atLimit, "a"));
        vm.expectRevert(ISuperBuilderCodeRegistry.URI_TOO_LONG.selector);
        registry.setCodeURI("partner_1", string.concat(atLimit, unicode"é"));
        vm.stopPrank();
        assertEq(registry.codeURI("partner_1"), atLimit);
    }

    function test_MetadataWritesRejectUnknownCodesAndZeroPayout() public {
        vm.startPrank(payout);
        vm.expectRevert(ISuperBuilderCodeRegistry.CODE_NOT_REGISTERED.selector);
        registry.setPayoutAddress("unknown", payout);
        vm.expectRevert(ISuperBuilderCodeRegistry.CODE_NOT_REGISTERED.selector);
        registry.setCodeURI("unknown", "");
        vm.stopPrank();
        _register();
        vm.prank(payout);
        vm.expectRevert(ISuperBuilderCodeRegistry.ZERO_ADDRESS.selector);
        registry.setPayoutAddress("partner_1", address(0));
    }

    function test_OnlyAdminsRegisterAndOnlyAssignedAddressUpdates() public {
        address[3] memory cannotRegister = [otherPayout, payout, address(this)];
        for (uint256 i; i < cannotRegister.length; ++i) {
            vm.prank(cannotRegister[i]);
            vm.expectRevert(_unauthorized(cannotRegister[i], bytes32(0)));
            registry.registerCode("partner_1", PARTNER, payout, URI);
        }
        _register();
        address[3] memory cannotUpdate = [governance, otherPayout, address(this)];
        for (uint256 i; i < cannotUpdate.length; ++i) {
            vm.startPrank(cannotUpdate[i]);
            vm.expectRevert(ISuperBuilderCodeRegistry.NOT_CODE_OWNER.selector);
            registry.setPayoutAddress("partner_1", otherPayout);
            vm.expectRevert(ISuperBuilderCodeRegistry.NOT_CODE_OWNER.selector);
            registry.setCodeURI("partner_1", "");
            // Matching existing values must still require ownership.
            vm.expectRevert(ISuperBuilderCodeRegistry.NOT_CODE_OWNER.selector);
            registry.setPayoutAddress("partner_1", payout);
            vm.expectRevert(ISuperBuilderCodeRegistry.NOT_CODE_OWNER.selector);
            registry.setCodeURI("partner_1", URI);
            vm.stopPrank();
        }
        vm.prank(payout);
        vm.expectRevert(_unauthorized(payout, bytes32(0)));
        registry.grantRole(bytes32(0), payout);
    }

    function test_AdminGrantAndRevocationControlIssuanceOnly() public {
        _register();
        address next = makeAddr("nextAdmin");
        vm.prank(governance);
        registry.grantRole(bytes32(0), next);
        vm.startPrank(next);
        registry.registerCode("new", PARTNER, next, "");
        vm.expectRevert(ISuperBuilderCodeRegistry.NOT_CODE_OWNER.selector);
        registry.setCodeURI("partner_1", "");
        vm.expectRevert(ISuperBuilderCodeRegistry.CODE_ALREADY_REGISTERED.selector);
        registry.registerCode("partner_1", keccak256("other"), next, "");
        vm.stopPrank();
        vm.prank(governance);
        registry.revokeRole(bytes32(0), next);
        vm.startPrank(next);
        vm.expectRevert(_unauthorized(next, bytes32(0)));
        registry.registerCode("another", PARTNER, next, "");
        // Removing admin does not remove authority over a code assigned to this address.
        registry.setCodeURI("new", "updated");
        vm.stopPrank();
        assertEq(registry.partnerId("partner_1"), PARTNER);
        assertEq(registry.partnerId("new"), PARTNER);
        assertEq(registry.codeURI("new"), "updated");
    }

    function test_PreviousRoleHashesCannotAuthorizeWrites() public {
        _register();
        vm.startPrank(governance);
        registry.grantRole(keccak256("REGISTRAR_ROLE"), otherPayout);
        registry.grantRole(keccak256("METADATA_MANAGER_ROLE"), otherPayout);
        vm.stopPrank();
        vm.startPrank(otherPayout);
        vm.expectRevert(_unauthorized(otherPayout, bytes32(0)));
        registry.registerCode("new", PARTNER, otherPayout, "");
        vm.expectRevert(ISuperBuilderCodeRegistry.NOT_CODE_OWNER.selector);
        registry.setPayoutAddress("partner_1", otherPayout);
        vm.expectRevert(ISuperBuilderCodeRegistry.NOT_CODE_OWNER.selector);
        registry.setCodeURI("partner_1", "");
        vm.stopPrank();
    }

    function test_AddressRotationImmediatelyTransfersControl() public {
        _register();
        vm.prank(payout);
        registry.setPayoutAddress("partner_1", otherPayout);
        vm.startPrank(payout);
        vm.expectRevert(ISuperBuilderCodeRegistry.NOT_CODE_OWNER.selector);
        registry.setPayoutAddress("partner_1", payout);
        vm.expectRevert(ISuperBuilderCodeRegistry.NOT_CODE_OWNER.selector);
        registry.setCodeURI("partner_1", "old owner");
        vm.stopPrank();
        vm.startPrank(otherPayout);
        registry.setCodeURI("partner_1", "new owner");
        registry.setPayoutAddress("partner_1", governance);
        vm.stopPrank();
        // Governance can edit only once it becomes the assigned address.
        vm.prank(governance);
        registry.setCodeURI("partner_1", "governance owns this code");
        vm.prank(otherPayout);
        vm.expectRevert(ISuperBuilderCodeRegistry.NOT_CODE_OWNER.selector);
        registry.setCodeURI("partner_1", "former owner");
        assertEq(registry.partnerId("partner_1"), PARTNER);
        assertEq(registry.payoutAddress("partner_1"), governance);
        assertEq(registry.codeURI("partner_1"), "governance owns this code");
    }

    function test_SamePartnerDifferentAddressesCannotEditEachOthersCodes() public {
        _register();
        vm.prank(governance);
        registry.registerCode("partner_2", PARTNER, otherPayout, "second");
        vm.startPrank(payout);
        vm.expectRevert(ISuperBuilderCodeRegistry.NOT_CODE_OWNER.selector);
        registry.setPayoutAddress("partner_2", payout);
        vm.expectRevert(ISuperBuilderCodeRegistry.NOT_CODE_OWNER.selector);
        registry.setCodeURI("partner_2", "stolen");
        registry.setCodeURI("partner_1", "first updated");
        vm.stopPrank();
        vm.startPrank(otherPayout);
        vm.expectRevert(ISuperBuilderCodeRegistry.NOT_CODE_OWNER.selector);
        registry.setPayoutAddress("partner_1", otherPayout);
        vm.expectRevert(ISuperBuilderCodeRegistry.NOT_CODE_OWNER.selector);
        registry.setCodeURI("partner_1", "stolen");
        registry.setCodeURI("partner_2", "second updated");
        vm.stopPrank();
        assertEq(registry.codeURI("partner_1"), "first updated");
        assertEq(registry.codeURI("partner_2"), "second updated");
    }

    function test_RotatingOneCodeDoesNotTransferOtherCodes() public {
        _register();
        vm.prank(governance);
        registry.registerCode("partner_2", PARTNER, payout, "second");
        vm.startPrank(payout);
        registry.setPayoutAddress("partner_1", otherPayout);
        registry.setCodeURI("partner_2", "still mine");
        vm.stopPrank();
        vm.startPrank(otherPayout);
        registry.setCodeURI("partner_1", "now mine");
        vm.expectRevert(ISuperBuilderCodeRegistry.NOT_CODE_OWNER.selector);
        registry.setCodeURI("partner_2", "stolen");
        vm.stopPrank();
        assertEq(registry.payoutAddress("partner_2"), payout);
        assertEq(registry.codeURI("partner_2"), "still mine");
    }

    function testFuzz_MetadataNeverChangesIdentity(
        bytes32 identity,
        address recipient,
        string memory uri
    )
        public
    {
        vm.assume(identity != bytes32(0) && recipient != address(0));
        vm.assume(bytes(uri).length <= 2048);
        vm.prank(governance);
        registry.registerCode("fuzz_partner", identity, payout, URI);
        vm.prank(payout);
        registry.setPayoutAddress("fuzz_partner", recipient);
        if (recipient != payout) {
            vm.startPrank(payout);
            vm.expectRevert(ISuperBuilderCodeRegistry.NOT_CODE_OWNER.selector);
            registry.setCodeURI("fuzz_partner", uri);
            vm.expectRevert(ISuperBuilderCodeRegistry.NOT_CODE_OWNER.selector);
            registry.setPayoutAddress("fuzz_partner", payout);
            vm.stopPrank();
        }
        vm.prank(recipient);
        registry.setCodeURI("fuzz_partner", uri);
        assertEq(registry.partnerId("fuzz_partner"), identity);
        assertTrue(registry.isRegistered("fuzz_partner"));
        assertEq(registry.payoutAddress("fuzz_partner"), recipient);
        assertEq(registry.codeURI("fuzz_partner"), uri);
    }

    function _register() internal {
        vm.prank(governance);
        registry.registerCode("partner_1", PARTNER, payout, URI);
    }

    function _unauthorized(address caller, bytes32 role) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, caller, role);
    }
}
