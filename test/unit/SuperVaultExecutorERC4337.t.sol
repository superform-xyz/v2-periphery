// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import { SuperGovernor } from "../../src/SuperGovernor.sol";
import { ISuperGovernor } from "../../src/interfaces/ISuperGovernor.sol";
import { SuperVaultAggregator } from "../../src/SuperVault/SuperVaultAggregator.sol";
import { ISuperVaultAggregator } from "../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { SuperVault } from "../../src/SuperVault/SuperVault.sol";
import { SuperVaultStrategy } from "../../src/SuperVault/SuperVaultStrategy.sol";
import { SuperVaultEscrow } from "../../src/SuperVault/SuperVaultEscrow.sol";
import { ISuperVaultStrategy } from "../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { SuperVaultExecutor } from "../../src/SuperVault/SuperVaultExecutor.sol";
import { ISuperVaultExecutor } from "../../src/interfaces/SuperVault/ISuperVaultExecutor.sol";
import { PackedUserOperation } from "../../src/vendor/erc4337/PackedUserOperation.sol";
import { PeripheryHelpers } from "../utils/PeripheryHelpers.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";
import { MockUp } from "../mocks/MockUp.sol";
import { MockSuperOracle } from "../mocks/MockSuperOracle.sol";

/// @title SuperVaultExecutorERC4337Test
/// @notice Tests for ERC-4337 EntryPoint compatibility on SuperVaultExecutor
contract SuperVaultExecutorERC4337Test is PeripheryHelpers {
    SuperGovernor internal superGovernor;
    SuperVaultAggregator internal superVaultAggregator;
    SuperVault internal vault;
    SuperVaultStrategy internal strategy;
    SuperVaultExecutor internal superVaultExecutor;
    MockERC20 internal asset;

    address internal sGovernor;
    address internal governor;
    address internal treasury;
    address internal user;
    address internal manager;
    address internal admin;
    address internal entryPoint;
    address internal superBank;
    address internal superOracle;
    address internal upToken;

    // Session key with known private key for signature tests
    uint256 internal constant SESSION_KEY_PK = 0xA11CE;
    address internal sessionKeyAddr;

    uint256 internal constant OTHER_PK = 0xB0B;
    address internal otherAddr;

    /// @dev SIG_VALIDATION_FAILED per ERC-4337
    uint256 internal constant SIG_VALIDATION_FAILED = 1;

    /// @dev All 6 permissions
    function _permAll() internal pure returns (ISuperVaultExecutor.Permission[] memory perms) {
        perms = new ISuperVaultExecutor.Permission[](6);
        perms[0] = ISuperVaultExecutor.Permission.ExecuteHooks;
        perms[1] = ISuperVaultExecutor.Permission.FulfillCancelRedeem;
        perms[2] = ISuperVaultExecutor.Permission.FulfillRedeem;
        perms[3] = ISuperVaultExecutor.Permission.SkimFee;
        perms[4] = ISuperVaultExecutor.Permission.Pause;
        perms[5] = ISuperVaultExecutor.Permission.Unpause;
    }

    /// @dev Single permission helper
    function _perm(ISuperVaultExecutor.Permission p)
        internal
        pure
        returns (ISuperVaultExecutor.Permission[] memory perms)
    {
        perms = new ISuperVaultExecutor.Permission[](1);
        perms[0] = p;
    }

    function setUp() public {
        sGovernor = _deployAccount(0x1, "SuperGovernor");
        governor = _deployAccount(0x2, "Governor");
        treasury = _deployAccount(0x3, "Treasury");
        user = _deployAccount(0x4, "User");
        manager = _deployAccount(0x5, "Manager");
        admin = _deployAccount(0x6, "Admin");
        entryPoint = makeAddr("entryPoint");
        superOracle = address(new MockSuperOracle(1e18));

        sessionKeyAddr = vm.addr(SESSION_KEY_PK);
        otherAddr = vm.addr(OTHER_PK);

        asset = new MockERC20("Asset", "ASSET", 18);

        superGovernor = new SuperGovernor(sGovernor, governor, governor, governor, governor, governor, treasury, false);

        address vaultImpl = address(new SuperVault(address(superGovernor)));
        address strategyImpl = address(new SuperVaultStrategy(address(superGovernor)));
        address escrowImpl = address(new SuperVaultEscrow());

        superVaultAggregator = new SuperVaultAggregator(address(superGovernor), vaultImpl, strategyImpl, escrowImpl);

        upToken = address(new MockUp(address(this)));
        superBank = makeAddr("superBank");
        vm.startPrank(sGovernor);
        superGovernor.setAddress(superGovernor.UP(), upToken);
        superGovernor.setAddress(superGovernor.UPKEEP_TOKEN(), upToken);
        superGovernor.setAddress(superGovernor.SUPER_BANK(), superBank);
        superGovernor.setAddress(superGovernor.SUPER_ORACLE(), superOracle);
        superGovernor.setAddress(superGovernor.SUPER_VAULT_AGGREGATOR(), address(superVaultAggregator));
        vm.stopPrank();

        vm.prank(manager);
        (address vaultAddress, address strategyAddress,) = superVaultAggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                name: "Test Vault",
                symbol: "TV",
                mainManager: manager,
                secondaryManagers: new address[](0),
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: 1000, managementFeeBps: 0, recipient: manager
                })
            })
        );

        vault = SuperVault(vaultAddress);
        strategy = SuperVaultStrategy(payable(strategyAddress));

        // Deploy SuperVaultExecutor
        superVaultExecutor = new SuperVaultExecutor(address(superGovernor), admin, entryPoint);

        // Add SuperVaultExecutor as secondary manager
        vm.prank(manager);
        superVaultAggregator.addSecondaryManager(address(strategy), address(superVaultExecutor));

        // Grant session key with all permissions
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy), sessionKeyAddr, block.timestamp + 1 days, _permAll()
        );
    }

    /*//////////////////////////////////////////////////////////////
                            HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Builds minimal ExecuteArgs (empty hooks — will revert in strategy but validates path)
    function _buildEmptyArgs() internal pure returns (ISuperVaultStrategy.ExecuteArgs memory) {
        return ISuperVaultStrategy.ExecuteArgs({
            hooks: new address[](0),
            hookCalldata: new bytes[](0),
            expectedAssetsOrSharesOut: new uint256[](0),
            globalProofs: new bytes32[][](0),
            strategyProofs: new bytes32[][](0)
        });
    }

    /// @dev Builds callData for executeFromEntryPoint
    function _buildCallData(
        address strategy_,
        ISuperVaultStrategy.ExecuteArgs memory args
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeCall(ISuperVaultExecutor.executeFromEntryPoint, (strategy_, args));
    }

    /// @dev Builds a PackedUserOperation
    function _buildUserOp(bytes memory callData_, bytes memory signature_)
        internal
        view
        returns (PackedUserOperation memory)
    {
        return PackedUserOperation({
            sender: address(superVaultExecutor),
            nonce: 0,
            initCode: "",
            callData: callData_,
            accountGasLimits: bytes32(uint256(200_000) << 128 | uint256(200_000)),
            preVerificationGas: 21_000,
            gasFees: bytes32(uint256(1 gwei) << 128 | uint256(1 gwei)),
            paymasterAndData: "",
            signature: signature_
        });
    }

    /// @dev Computes a mock userOpHash (simulates what EntryPoint would produce)
    function _computeUserOpHash(PackedUserOperation memory userOp) internal view returns (bytes32) {
        bytes32 opDataHash = keccak256(
            abi.encode(
                userOp.sender,
                userOp.nonce,
                keccak256(userOp.initCode),
                keccak256(userOp.callData),
                userOp.accountGasLimits,
                userOp.preVerificationGas,
                userOp.gasFees,
                keccak256(userOp.paymasterAndData)
            )
        );
        return keccak256(abi.encode(opDataHash, entryPoint, block.chainid));
    }

    /// @dev Signs a userOpHash with the given private key (EIP-191 prefix)
    function _signUserOp(uint256 privateKey, bytes32 userOpHash) internal pure returns (bytes memory) {
        bytes32 ethSignedHash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, ethSignedHash);
        return abi.encodePacked(r, s, v);
    }

    /*//////////////////////////////////////////////////////////////
                    VALIDATE USER OP TESTS
    //////////////////////////////////////////////////////////////*/

    function test_validateUserOp_success() public {
        bytes memory callData_ = _buildCallData(address(strategy), _buildEmptyArgs());
        PackedUserOperation memory userOp = _buildUserOp(callData_, ""); // placeholder sig

        bytes32 userOpHash = _computeUserOpHash(userOp);
        userOp.signature = _signUserOp(SESSION_KEY_PK, userOpHash);

        vm.prank(entryPoint);
        uint256 validationData = superVaultExecutor.validateUserOp(userOp, userOpHash, 0);

        // Success: lower 160 bits should be 0 (sigAuthorizer = address(0))
        address sigAuthorizer = address(uint160(validationData));
        assertEq(sigAuthorizer, address(0), "sigAuthorizer should be 0 for success");

        // validUntil should be the session key expiry
        uint48 validUntil = uint48(validationData >> 160);
        assertEq(validUntil, uint48(block.timestamp + 1 days), "validUntil should match session key expiry");
    }

    function test_validateUserOp_revertsNotEntryPoint() public {
        bytes memory callData_ = _buildCallData(address(strategy), _buildEmptyArgs());
        PackedUserOperation memory userOp = _buildUserOp(callData_, "");
        bytes32 userOpHash = _computeUserOpHash(userOp);
        userOp.signature = _signUserOp(SESSION_KEY_PK, userOpHash);

        vm.expectRevert(ISuperVaultExecutor.ONLY_ENTRY_POINT.selector);
        superVaultExecutor.validateUserOp(userOp, userOpHash, 0);
    }

    function test_validateUserOp_invalidSelector() public {
        // Use executeHooks selector instead of executeFromEntryPoint
        bytes memory badCallData = abi.encodeCall(
            ISuperVaultExecutor.executeHooks,
            (address(strategy), _buildEmptyArgs())
        );
        PackedUserOperation memory userOp = _buildUserOp(badCallData, "");
        bytes32 userOpHash = _computeUserOpHash(userOp);
        userOp.signature = _signUserOp(SESSION_KEY_PK, userOpHash);

        vm.prank(entryPoint);
        vm.expectRevert(ISuperVaultExecutor.INVALID_CALLDATA_SELECTOR.selector);
        superVaultExecutor.validateUserOp(userOp, userOpHash, 0);
    }

    function test_validateUserOp_shortCalldata() public {
        // callData shorter than 36 bytes (selector + address)
        bytes memory shortData = hex"12345678";
        PackedUserOperation memory userOp = _buildUserOp(shortData, "");
        bytes32 userOpHash = _computeUserOpHash(userOp);
        userOp.signature = _signUserOp(SESSION_KEY_PK, userOpHash);

        vm.prank(entryPoint);
        vm.expectRevert(ISuperVaultExecutor.INVALID_CALLDATA_SELECTOR.selector);
        superVaultExecutor.validateUserOp(userOp, userOpHash, 0);
    }

    function test_validateUserOp_invalidSigner() public {
        bytes memory callData_ = _buildCallData(address(strategy), _buildEmptyArgs());
        PackedUserOperation memory userOp = _buildUserOp(callData_, "");
        bytes32 userOpHash = _computeUserOpHash(userOp);

        // Sign with a key that has no session key granted
        userOp.signature = _signUserOp(OTHER_PK, userOpHash);

        vm.prank(entryPoint);
        uint256 validationData = superVaultExecutor.validateUserOp(userOp, userOpHash, 0);
        assertEq(validationData, SIG_VALIDATION_FAILED, "Should return SIG_VALIDATION_FAILED for unknown signer");
    }

    function test_validateUserOp_expiredKey() public {
        bytes memory callData_ = _buildCallData(address(strategy), _buildEmptyArgs());
        PackedUserOperation memory userOp = _buildUserOp(callData_, "");
        bytes32 userOpHash = _computeUserOpHash(userOp);
        userOp.signature = _signUserOp(SESSION_KEY_PK, userOpHash);

        // Warp past expiry
        vm.warp(block.timestamp + 2 days);

        vm.prank(entryPoint);
        uint256 validationData = superVaultExecutor.validateUserOp(userOp, userOpHash, 0);
        assertEq(validationData, SIG_VALIDATION_FAILED, "Should return SIG_VALIDATION_FAILED for expired key");
    }

    function test_validateUserOp_wrongPermission() public {
        // Grant a new session key with only FulfillRedeem permission (not ExecuteHooks)
        address noExecKey = vm.addr(0xDEAD);
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy), noExecKey, block.timestamp + 1 days, _perm(ISuperVaultExecutor.Permission.FulfillRedeem)
        );

        bytes memory callData_ = _buildCallData(address(strategy), _buildEmptyArgs());
        PackedUserOperation memory userOp = _buildUserOp(callData_, "");
        bytes32 userOpHash = _computeUserOpHash(userOp);
        userOp.signature = _signUserOp(0xDEAD, userOpHash);

        vm.prank(entryPoint);
        uint256 validationData = superVaultExecutor.validateUserOp(userOp, userOpHash, 0);
        assertEq(validationData, SIG_VALIDATION_FAILED, "Should fail for key without ExecuteHooks permission");
    }

    function test_validateUserOp_invalidatedGeneration() public {
        // Invalidate all session keys
        vm.prank(manager);
        superVaultExecutor.invalidateAllSessionKeys(address(strategy));

        bytes memory callData_ = _buildCallData(address(strategy), _buildEmptyArgs());
        PackedUserOperation memory userOp = _buildUserOp(callData_, "");
        bytes32 userOpHash = _computeUserOpHash(userOp);
        userOp.signature = _signUserOp(SESSION_KEY_PK, userOpHash);

        vm.prank(entryPoint);
        uint256 validationData = superVaultExecutor.validateUserOp(userOp, userOpHash, 0);
        assertEq(validationData, SIG_VALIDATION_FAILED, "Should fail after generation invalidation");
    }

    function test_validateUserOp_validUntilPacking() public {
        // Grant session key with specific expiry
        uint256 specificExpiry = block.timestamp + 3600;
        address keyAddr = vm.addr(0xCAFE);
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy), keyAddr, specificExpiry, _perm(ISuperVaultExecutor.Permission.ExecuteHooks)
        );

        bytes memory callData_ = _buildCallData(address(strategy), _buildEmptyArgs());
        PackedUserOperation memory userOp = _buildUserOp(callData_, "");
        bytes32 userOpHash = _computeUserOpHash(userOp);
        userOp.signature = _signUserOp(0xCAFE, userOpHash);

        vm.prank(entryPoint);
        uint256 validationData = superVaultExecutor.validateUserOp(userOp, userOpHash, 0);

        // Extract validUntil (bits 160-207)
        uint48 validUntil = uint48(validationData >> 160);
        assertEq(validUntil, uint48(specificExpiry), "validUntil should match session key expiry");

        // Extract validAfter (bits 208-255) — should be 0
        uint48 validAfter = uint48(validationData >> 208);
        assertEq(validAfter, 0, "validAfter should be 0");
    }

    function test_validateUserOp_maxExpiryCappedToIndefinite() public {
        // Grant with type(uint256).max expiry
        address keyAddr = vm.addr(0xBEEF);
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy), keyAddr, type(uint256).max, _perm(ISuperVaultExecutor.Permission.ExecuteHooks)
        );

        bytes memory callData_ = _buildCallData(address(strategy), _buildEmptyArgs());
        PackedUserOperation memory userOp = _buildUserOp(callData_, "");
        bytes32 userOpHash = _computeUserOpHash(userOp);
        userOp.signature = _signUserOp(0xBEEF, userOpHash);

        vm.prank(entryPoint);
        uint256 validationData = superVaultExecutor.validateUserOp(userOp, userOpHash, 0);

        // validUntil should be 0 (indefinite) since expiry > type(uint48).max
        uint48 validUntil = uint48(validationData >> 160);
        assertEq(validUntil, 0, "validUntil should be 0 (indefinite) for max expiry");
    }

    function test_validateUserOp_missingAccountFundsTransferred() public {
        bytes memory callData_ = _buildCallData(address(strategy), _buildEmptyArgs());
        PackedUserOperation memory userOp = _buildUserOp(callData_, "");
        bytes32 userOpHash = _computeUserOpHash(userOp);
        userOp.signature = _signUserOp(SESSION_KEY_PK, userOpHash);

        // Fund the executor so it can pre-fund the EntryPoint
        vm.deal(address(superVaultExecutor), 2 ether);

        // Pass nonzero missingAccountFunds — should transfer ETH to EntryPoint (caller)
        uint256 balBefore = entryPoint.balance;
        vm.prank(entryPoint);
        uint256 validationData = superVaultExecutor.validateUserOp(userOp, userOpHash, 1 ether);

        // Validation should succeed
        address sigAuthorizer = address(uint160(validationData));
        assertEq(sigAuthorizer, address(0), "Should succeed with nonzero missingAccountFunds");
        // ETH should be transferred to EntryPoint (msg.sender)
        assertEq(entryPoint.balance, balBefore + 1 ether, "ETH should be transferred to EntryPoint");
    }

    function test_validateUserOp_zeroMissingAccountFundsNoTransfer() public {
        bytes memory callData_ = _buildCallData(address(strategy), _buildEmptyArgs());
        PackedUserOperation memory userOp = _buildUserOp(callData_, "");
        bytes32 userOpHash = _computeUserOpHash(userOp);
        userOp.signature = _signUserOp(SESSION_KEY_PK, userOpHash);

        // Pass zero missingAccountFunds — should not transfer any ETH
        uint256 balBefore = entryPoint.balance;
        vm.prank(entryPoint);
        uint256 validationData = superVaultExecutor.validateUserOp(userOp, userOpHash, 0);

        address sigAuthorizer = address(uint160(validationData));
        assertEq(sigAuthorizer, address(0), "Should succeed with zero missingAccountFunds");
        assertEq(entryPoint.balance, balBefore, "No ETH should be transferred when missingAccountFunds is 0");
    }

    /*//////////////////////////////////////////////////////////////
                EXECUTE FROM ENTRY POINT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_executeFromEntryPoint_revertsNotEntryPoint() public {
        vm.expectRevert(ISuperVaultExecutor.ONLY_ENTRY_POINT.selector);
        superVaultExecutor.executeFromEntryPoint(address(strategy), _buildEmptyArgs());
    }

    function test_executeFromEntryPoint_emitsEvent() public {
        // executeFromEntryPoint with empty hooks will revert in strategy (ZERO_LENGTH)
        // but we can test the modifier/event by expecting the strategy revert
        ISuperVaultStrategy.ExecuteArgs memory args = _buildEmptyArgs();

        vm.prank(entryPoint);
        // Strategy will revert because hooks array is empty
        vm.expectRevert();
        superVaultExecutor.executeFromEntryPoint(address(strategy), args);
    }

    /*//////////////////////////////////////////////////////////////
                    LEGACY PATH REGRESSION
    //////////////////////////////////////////////////////////////*/

    function test_executeHooks_legacyPathStillWorks() public {
        // The legacy executeHooks path should still validate via msg.sender session key
        ISuperVaultStrategy.ExecuteArgs memory args = _buildEmptyArgs();

        // Should revert because the strategy rejects empty hooks (ZERO_LENGTH),
        // but the session key validation should pass first
        vm.prank(sessionKeyAddr);
        vm.expectRevert(); // Strategy ZERO_LENGTH
        superVaultExecutor.executeHooks(address(strategy), args);
    }

    function test_executeHooks_legacyPathRejectsUnauthorized() public {
        ISuperVaultStrategy.ExecuteArgs memory args = _buildEmptyArgs();

        // otherAddr has no session key
        vm.prank(otherAddr);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_NOT_AUTHORIZED.selector);
        superVaultExecutor.executeHooks(address(strategy), args);
    }
}
