// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

// External
import { ECDSA } from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

// Superform
import { SuperGovernor } from "../../src/SuperGovernor.sol";
import { SuperVaultAggregator } from "../../src/SuperVault/SuperVaultAggregator.sol";
import { SuperVault } from "../../src/SuperVault/SuperVault.sol";
import { SuperVaultStrategy } from "../../src/SuperVault/SuperVaultStrategy.sol";
import { SuperVaultEscrow } from "../../src/SuperVault/SuperVaultEscrow.sol";
import { ISuperVaultAggregator } from "../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ECDSAPPSOracle } from "../../src/oracles/ECDSAPPSOracle.sol";
import { ISuperVaultStrategy } from "../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { IECDSAPPSOracle } from "../../src/interfaces/oracles/IECDSAPPSOracle.sol";

// Test
import { BaseSuperVaultTest } from "../integration/SuperVault/BaseSuperVaultTest.t.sol";

contract ECDSAPPSOracleTest is BaseSuperVaultTest {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // Test accounts
    address public user;
    address public validator1;
    address public validator2;
    address public validator3;
    address public mockManager;
    address public governorAddress;

    // SuperVault
    address public sv;
    address public svStrategy;

    // Mock data
    uint256 public constant PPS = 1e18; // 1.0
    uint256 public constant PPS_STDEV = 1e16; // 0.01

    ECDSAPPSOracle public oracleECDSA;

    SuperGovernor public governor;
    SuperVaultAggregator public aggregatorSuperVault;

    function setUp() public override {
        super.setUp();

        // Set up test account
        user = _deployAccount(0x2, "User");

        // Create validators
        validator1 = _deployAccount(validator1PrivateKey, "Validator1");
        validator2 = _deployAccount(validator2PrivateKey, "Validator2");
        validator3 = _deployAccount(validator3PrivateKey, "Validator3");

        // Set up mock strategy for testing
        mockManager = _deployAccount(0x6, "mockManager");

        // Get the governor role to call validator-related functions
        governorAddress = _deployAccount(0x7, "GovernorRole");

        // Create a new governor specifically for these tests
        governor =
            new SuperGovernor(governorAddress, governorAddress, governorAddress, governorAddress, TREASURY, CHAIN_1_POLYMER_PROVER);

        // Deploy implementation contracts first
        address vaultImpl = address(new SuperVault(address(governor)));
        address strategyImpl = address(new SuperVaultStrategy(address(governor)));
        address escrowImpl = address(new SuperVaultEscrow());

        // Deploy SuperVaultAggregator
        aggregatorSuperVault = new SuperVaultAggregator(address(governor), vaultImpl, strategyImpl, escrowImpl);

        (sv, svStrategy,) = aggregatorSuperVault.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                name: "TestVault",
                symbol: "TV",
                mainManager: mockManager,
                secondaryManagers: new address[](0),
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({ performanceFeeBps: 1000, managementFeeBps: 0, recipient: TREASURY }),
                maxUnpauseTimeLock: 0
            })
        );

        // Create a new ECDSAPPSOracle with our custom governor
        oracleECDSA = new ECDSAPPSOracle(address(governor), ECDSAPPS_ORACLE_KEY, ECDSAPPS_ORACLE_VERSION);

        vm.startPrank(governorAddress);
        governor.grantRole(governor.GOVERNOR_ROLE(), governorAddress);
        governor.grantRole(governor.SUPER_GOVERNOR_ROLE(), governorAddress);
        vm.stopPrank();

        // Add validators (requires GOVERNOR_ROLE)
        vm.startPrank(governorAddress);
        governor.addValidator(validator1);
        governor.addValidator(validator2);
        governor.addValidator(validator3);
        governor.setPPSOracleQuorum(2); // Set quorum to 2 validators

        // Set the SuperVaultAggregator
        governor.setAddress(governor.SUPER_VAULT_AGGREGATOR(), address(aggregatorSuperVault));

        // Set the active PPS Oracle
        governor.proposeActivePPSOracle(address(oracleECDSA));
        vm.warp(block.timestamp + 7 days);
        governor.executeActivePPSOracleChange();

        governor.proposeUpkeepPaymentsChange(false);
        vm.warp(block.timestamp + 8 days);
        governor.executeUpkeepPaymentsChange();

        governor.setAddress(governor.UP(), upToken);
        governor.setAddress(governor.SUPER_ORACLE(), address(superOracle));
        governor.setGasInfo(address(oracleECDSA), 10_000);

        vm.stopPrank();

        assertEq(governor.isActivePPSOracle(address(oracleECDSA)), true);

       
    }

    /*//////////////////////////////////////////////////////////////
                          CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/
    function test_Constructor() public view {
        // Test that constructor sets up the contract correctly
        assertEq(address(oracleECDSA.SUPER_GOVERNOR()), address(governor));
    }

    function test_Constructor_ZeroAddressReverts() public {
        // Test constructor reverts with invalid address
        vm.expectRevert(IECDSAPPSOracle.INVALID_VALIDATOR.selector);
        new ECDSAPPSOracle(address(0), ECDSAPPS_ORACLE_KEY, ECDSAPPS_ORACLE_VERSION);
    }

    /*//////////////////////////////////////////////////////////////
                          UPDATE PPS TESTS
    //////////////////////////////////////////////////////////////*/
    function test_UpdatePPS_Success() public {
        // Create valid proofs from multiple validators
        bytes[] memory proofs = _createValidProofs(
            address(svStrategy),
            PPS,
            block.timestamp,
            new uint256[](0)
        );

        // Call batchUpdatePPS with a single entry
        address[] memory strategies = new address[](1);
        strategies[0] = address(svStrategy);
        
        bytes[][] memory proofsArray = new bytes[][](1);
        proofsArray[0] = proofs;
        
        uint256[] memory ppss = new uint256[](1);
        ppss[0] = PPS;
        
        uint256[] memory validatorSets = new uint256[](1);
        validatorSets[0] = 2;
        
        uint256[] memory totalValidators = new uint256[](1);
        totalValidators[0] = 3;
        
        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = block.timestamp;

        oracleECDSA.updatePPS(
            IECDSAPPSOracle.UpdatePPSArgs({
                strategies: strategies,
                proofsArray: proofsArray,
                ppss: ppss,
                timestamps: timestamps
            })
        );
    }

    function test_UpdatePPS_InvalidReplay() public {
        // Create valid proofs from multiple validators
        bytes[] memory proofs = _createValidProofs(
            address(svStrategy),
            PPS,
            block.timestamp,
            new uint256[](0)
        );

        // First call should succeed
        address[] memory strategies = new address[](1);
        strategies[0] = address(svStrategy);
        
        bytes[][] memory proofsArray = new bytes[][](1);
        proofsArray[0] = proofs;
        
        uint256[] memory ppss = new uint256[](1);
        ppss[0] = PPS;
        
        uint256[] memory validatorSets = new uint256[](1);
        validatorSets[0] = 2;
        
        uint256[] memory totalValidators = new uint256[](1);
        totalValidators[0] = 3;
        
        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = block.timestamp;

        oracleECDSA.updatePPS(
            IECDSAPPSOracle.UpdatePPSArgs({
                strategies: strategies,
                proofsArray: proofsArray,
                ppss: ppss,
                timestamps: timestamps
            })
        );

        // Second call with same proofs should emit ProofValidationFailedLowLevel event
        vm.expectEmit(true, false, false, false);
        emit IECDSAPPSOracle.ProofValidationFailedLowLevel(address(svStrategy), abi.encodeWithSelector(IECDSAPPSOracle.INVALID_VALIDATOR.selector));
        
        oracleECDSA.updatePPS(
            IECDSAPPSOracle.UpdatePPSArgs({
                strategies: strategies,
                proofsArray: proofsArray,
                ppss: ppss,
                timestamps: timestamps
            })
        );
    }

    function test_UpdatePPS_InvalidValidatorReverts() public {
        // Create valid proofs but with a non-validator
        uint256 nonValidatorPrivKey = 0x999;

        uint256[] memory signerKeys = new uint256[](2);
        signerKeys[0] = validator1PrivateKey;
        signerKeys[1] = nonValidatorPrivKey;

        // Create message hash with all parameters
        bytes32 structHash = keccak256(
            abi.encodePacked(
                oracleECDSA.UPDATE_PPS_TYPEHASH(),
                address(svStrategy),
                PPS,
                PPS_STDEV,
                uint256(2),
                uint256(3),
                block.timestamp,
                oracleECDSA.noncePerStrategy(address(svStrategy))
            )
        );
        bytes32 domainSeparator = oracleECDSA.domainSeparator();
        bytes32 digest = MessageHashUtils.toTypedDataHash(domainSeparator, structHash);

        // Create proofs array
        bytes[] memory proofs = new bytes[](signerKeys.length);
        for (uint256 i = 0; i < signerKeys.length; i++) {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKeys[i], digest);
            proofs[i] = abi.encodePacked(r, s, v);
        }

        // Call should emit ProofValidationFailedLowLevel event because one signer is not a validator
        vm.prank(user);
        vm.expectEmit(true, false, false, false);
        emit IECDSAPPSOracle.ProofValidationFailedLowLevel(address(svStrategy), abi.encodeWithSelector(IECDSAPPSOracle.INVALID_VALIDATOR.selector));
        
        address[] memory strategies = new address[](1);
        strategies[0] = address(svStrategy);
        
        bytes[][] memory proofsArray = new bytes[][](1);
        proofsArray[0] = proofs;
        
        uint256[] memory ppss = new uint256[](1);
        ppss[0] = PPS;
        
        uint256[] memory validatorSets = new uint256[](1);
        validatorSets[0] = 2;
        
        uint256[] memory totalValidators = new uint256[](1);
        totalValidators[0] = 3;
        
        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = block.timestamp;
        
        oracleECDSA.updatePPS(
            IECDSAPPSOracle.UpdatePPSArgs({
                strategies: strategies,
                proofsArray: proofsArray,
                ppss: ppss,
                timestamps: timestamps
            })
        );
    }

    function test_UpdatePPS_QuorumNotMetReverts() public {
        // Create proof with only one validator when quorum requires two
        uint256[] memory signerKeys = new uint256[](1);
        signerKeys[0] = validator1PrivateKey;

        bytes[] memory proofs = _createValidProofs(
            address(svStrategy),
            PPS,
            block.timestamp,
            signerKeys
        );

        // Call should emit ProofValidationFailedLowLevel event because quorum is not met (we set quorum to 2 in setUp)
        vm.prank(user);
        vm.expectEmit(true, false, false, false);
        emit IECDSAPPSOracle.ProofValidationFailedLowLevel(address(svStrategy), abi.encodeWithSelector(IECDSAPPSOracle.QUORUM_NOT_MET.selector));
        
        address[] memory strategies = new address[](1);
        strategies[0] = address(svStrategy);
        
        bytes[][] memory proofsArray = new bytes[][](1);
        proofsArray[0] = proofs;
        
        uint256[] memory ppss = new uint256[](1);
        ppss[0] = PPS;
        
        uint256[] memory validatorSets = new uint256[](1);
        validatorSets[0] = 1;
        
        uint256[] memory totalValidators = new uint256[](1);
        totalValidators[0] = 3;
        
        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = block.timestamp;
        
        oracleECDSA.updatePPS(
            IECDSAPPSOracle.UpdatePPSArgs({
                strategies: strategies,
                proofsArray: proofsArray,
                ppss: ppss,
                timestamps: timestamps
            })
        );
    }

    function test_UpdatePPS_DuplicateSignerReverts() public {
        // Create proof with the same validator signing twice
        bytes[] memory proofs = new bytes[](2);

        bytes32 structHash = keccak256(
            abi.encodePacked(
                oracleECDSA.UPDATE_PPS_TYPEHASH(),
                address(svStrategy),
                PPS,
                PPS_STDEV,
                uint256(2),
                uint256(3),
                block.timestamp,
                oracleECDSA.noncePerStrategy(address(svStrategy))
            )
        );
        bytes32 domainSeparator = oracleECDSA.domainSeparator();
        bytes32 digest = MessageHashUtils.toTypedDataHash(domainSeparator, structHash);

        // Use validator1 to sign both proofs
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(validator1PrivateKey, digest);
        proofs[0] = abi.encodePacked(r, s, v);
        proofs[1] = abi.encodePacked(r, s, v); // Same signature again

        // Call should emit ProofValidationFailedLowLevel event because of duplicate signers
        vm.prank(user);
        vm.expectEmit(true, false, false, false);
        emit IECDSAPPSOracle.ProofValidationFailedLowLevel(address(svStrategy), abi.encodeWithSelector(IECDSAPPSOracle.INVALID_PROOF.selector));
        
        address[] memory strategies = new address[](1);
        strategies[0] = address(svStrategy);
        
        bytes[][] memory proofsArray = new bytes[][](1);
        proofsArray[0] = proofs;
        
        uint256[] memory ppss = new uint256[](1);
        ppss[0] = PPS;
        
        uint256[] memory validatorSets = new uint256[](1);
        validatorSets[0] = 2;
        
        uint256[] memory totalValidators = new uint256[](1);
        totalValidators[0] = 3;
        
        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = block.timestamp;
        
        oracleECDSA.updatePPS(
            IECDSAPPSOracle.UpdatePPSArgs({
                strategies: strategies,
                proofsArray: proofsArray,
                ppss: ppss,
                timestamps: timestamps
            })
        );
    }

    function test_UpdatePPS_UnsortedSignersReverts() public {
        // Create proofs with signers in descending order (should fail)
        uint256[] memory signerKeys = new uint256[](2);
        
        // Determine which validator has a higher address and put it first
        address addr1 = vm.addr(validator1PrivateKey);
        address addr2 = vm.addr(validator2PrivateKey);
        
        if (addr1 > addr2) {
            signerKeys[0] = validator1PrivateKey; // Higher address first
            signerKeys[1] = validator2PrivateKey; // Lower address second
        } else {
            signerKeys[0] = validator2PrivateKey; // Higher address first
            signerKeys[1] = validator1PrivateKey; // Lower address second
        }

        // Create EIP712 structured hash with all parameters
        bytes32 structHash = keccak256(
            abi.encodePacked(
                oracleECDSA.UPDATE_PPS_TYPEHASH(),
                address(svStrategy),
                PPS,
                PPS_STDEV,
                uint256(2),
                uint256(3),
                block.timestamp,
                oracleECDSA.noncePerStrategy(address(svStrategy))
            )
        );
        bytes32 domainSeparator = oracleECDSA.domainSeparator();
        bytes32 digest = MessageHashUtils.toTypedDataHash(domainSeparator, structHash);

        // Create proofs array in wrong order (descending)
        bytes[] memory proofs = new bytes[](2);
        for (uint256 i = 0; i < 2; i++) {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKeys[i], digest);
            proofs[i] = abi.encodePacked(r, s, v);
        }

        // Call should emit ProofValidationFailedLowLevel event because signers are not in ascending order
        vm.prank(user);
        vm.expectEmit(true, false, false, false);
        emit IECDSAPPSOracle.ProofValidationFailedLowLevel(address(svStrategy), abi.encodeWithSelector(IECDSAPPSOracle.INVALID_PROOF.selector));
        
        address[] memory strategies = new address[](1);
        strategies[0] = address(svStrategy);
        
        bytes[][] memory proofsArray = new bytes[][](1);
        proofsArray[0] = proofs;
        
        uint256[] memory ppss = new uint256[](1);
        ppss[0] = PPS;
        
        uint256[] memory validatorSets = new uint256[](1);
        validatorSets[0] = 2;
        
        uint256[] memory totalValidators = new uint256[](1);
        totalValidators[0] = 3;
        
        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = block.timestamp;
        
        oracleECDSA.updatePPS(
            IECDSAPPSOracle.UpdatePPSArgs({
                strategies: strategies,
                proofsArray: proofsArray,
                ppss: ppss,
                timestamps: timestamps
            })
        );
    }

    function test_UpdatePPS_ValidatorCountMismatchReverts() public {
        uint256[] memory signerKeys = new uint256[](2);
        signerKeys[0] = validator1PrivateKey;
        signerKeys[1] = validator2PrivateKey;

        // Create digest with all parameters
         bytes32 structHash = keccak256(
            abi.encodePacked(
                oracleECDSA.UPDATE_PPS_TYPEHASH(),
                address(svStrategy),
                PPS,
                PPS_STDEV,
                uint256(1),
                uint256(3),
                block.timestamp,
                oracleECDSA.noncePerStrategy(address(svStrategy))
            )
        );
        bytes32 domainSeparator = oracleECDSA.domainSeparator();
        bytes32 digest = MessageHashUtils.toTypedDataHash(domainSeparator, structHash);

        // Create proofs array
        bytes[] memory proofs = new bytes[](signerKeys.length);
        for (uint256 i = 0; i < signerKeys.length; i++) {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKeys[i], digest);
            proofs[i] = abi.encodePacked(r, s, v);
        }

        vm.expectEmit(true, false, false, false);
        emit IECDSAPPSOracle.ProofValidationFailedLowLevel(address(svStrategy), abi.encodeWithSelector(IECDSAPPSOracle.INVALID_VALIDATOR_SET.selector));
        
        address[] memory strategies = new address[](1);
        strategies[0] = address(svStrategy);
        
        bytes[][] memory proofsArray = new bytes[][](1);
        proofsArray[0] = proofs;
        
        uint256[] memory ppss = new uint256[](1);
        ppss[0] = PPS;
        
        uint256[] memory validatorSets = new uint256[](1);
        validatorSets[0] = 1;
        
        uint256[] memory totalValidators = new uint256[](1);
        totalValidators[0] = 3;
        
        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = block.timestamp;
        
        oracleECDSA.updatePPS(
            IECDSAPPSOracle.UpdatePPSArgs({
                strategies: strategies,
                proofsArray: proofsArray,
                ppss: ppss,
                timestamps: timestamps
            })
        );
    }

    function test_UpdatePPS_InsufficientQuorumReverts() public {
        // Create only 1 proof when we need at least 2 for quorum
        bytes[] memory proofs = new bytes[](1);
        
        // Create a valid signature from validator1
        bytes32 structHash = keccak256(
            abi.encodePacked(
                oracleECDSA.UPDATE_PPS_TYPEHASH(),
                address(svStrategy),
                PPS,
                PPS_STDEV,
                block.timestamp,
                oracleECDSA.noncePerStrategy(address(svStrategy))
            )
        );
        bytes32 domainSeparator = oracleECDSA.domainSeparator();
        bytes32 digest = MessageHashUtils.toTypedDataHash(domainSeparator, structHash);
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(validator1PrivateKey, digest);
        proofs[0] = abi.encodePacked(r, s, v);

        vm.expectEmit(true, false, false, false);
        emit IECDSAPPSOracle.ProofValidationFailedLowLevel(address(svStrategy), abi.encodeWithSelector(IECDSAPPSOracle.QUORUM_NOT_MET.selector));
        
        address[] memory strategies = new address[](1);
        strategies[0] = address(svStrategy);
        
        bytes[][] memory proofsArray = new bytes[][](1);
        proofsArray[0] = proofs;
        
        uint256[] memory ppss = new uint256[](1);
        ppss[0] = PPS;
        
        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = block.timestamp;
        
        oracleECDSA.updatePPS(
            IECDSAPPSOracle.UpdatePPSArgs({
                strategies: strategies,
                proofsArray: proofsArray,
                ppss: ppss,
                timestamps: timestamps
            })
        );
    }

    function test_UpdatePPS_EmptyProofsArrayReverts() public {
        // Create empty proof array to trigger ZERO_LENGTH_ARRAY error
        bytes[] memory emptyProofs = new bytes[](0);

        vm.expectEmit(true, false, false, false);
        emit IECDSAPPSOracle.ProofValidationFailedLowLevel(address(svStrategy), abi.encodeWithSelector(IECDSAPPSOracle.ZERO_LENGTH_ARRAY.selector));
        
        address[] memory strategies = new address[](1);
        strategies[0] = address(svStrategy);
        
        bytes[][] memory proofsArray = new bytes[][](1);
        proofsArray[0] = emptyProofs;
        
        uint256[] memory ppss = new uint256[](1);
        ppss[0] = PPS;
        
        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = block.timestamp;
        
        oracleECDSA.updatePPS(
            IECDSAPPSOracle.UpdatePPSArgs({
                strategies: strategies,
                proofsArray: proofsArray,
                ppss: ppss,
                timestamps: timestamps
            })
        );
    }

    function test_UpdatePPS_EmptyProofsReverts() public {
        // Create empty proofs array
        bytes[] memory proofs = new bytes[](0);

        // Call should emit ProofValidationFailedLowLevel event because proofs array is empty
        vm.prank(user);
        vm.expectEmit(true, false, false, false);
        emit IECDSAPPSOracle.ProofValidationFailedLowLevel(address(svStrategy), abi.encodeWithSelector(IECDSAPPSOracle.ZERO_LENGTH_ARRAY.selector));
        
        address[] memory strategies = new address[](1);
        strategies[0] = address(svStrategy);
        
        bytes[][] memory proofsArray = new bytes[][](1);
        proofsArray[0] = proofs;
        
        uint256[] memory ppss = new uint256[](1);
        ppss[0] = PPS;
        
        uint256[] memory validatorSets = new uint256[](1);
        validatorSets[0] = 0;
        
        uint256[] memory totalValidators = new uint256[](1);
        totalValidators[0] = 3;
        
        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = block.timestamp;
        
        oracleECDSA.updatePPS(
            IECDSAPPSOracle.UpdatePPSArgs({
                strategies: strategies,
                proofsArray: proofsArray,
                ppss: ppss,
                timestamps: timestamps
            })
        );
    }

    function test_UpdatePPS_NotActivePPSOracleReverts() public {
        // First set another oracle as active
        address newOracle = address(0xABC);

        // For changing the oracle after first time, we need to use the timelock pattern
        vm.startPrank(governorAddress);
        governor.proposeActivePPSOracle(newOracle);
        vm.warp(block.timestamp + 7 days);
        governor.executeActivePPSOracleChange();
        vm.stopPrank();

        // Create valid proofs
        bytes[] memory proofs = _createValidProofs(
            address(svStrategy),
            PPS,
            block.timestamp,
            new uint256[](0)
        );
        
        address[] memory strategies = new address[](1);
        strategies[0] = address(svStrategy);
        
        bytes[][] memory proofsArray = new bytes[][](1);
        proofsArray[0] = proofs;
        
        uint256[] memory ppss = new uint256[](1);
        ppss[0] = PPS;
        
        uint256[] memory validatorSets = new uint256[](1);
        validatorSets[0] = 2;
        
        uint256[] memory totalValidators = new uint256[](1);
        totalValidators[0] = 3;
        
        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = block.timestamp;
        
        oracleECDSA.updatePPS(
            IECDSAPPSOracle.UpdatePPSArgs({
                strategies: strategies,
                proofsArray: proofsArray,
                ppss: ppss,
                timestamps: timestamps
            })
        );
    }

    /*//////////////////////////////////////////////////////////////
                      BATCH UPDATE PPS TESTS
    //////////////////////////////////////////////////////////////*/
    struct BatchTestData {
        address strategy1;
        address strategy2;
        address[] strategies;
        uint256[] ppss;
        uint256[] validatorSets;
        uint256[] totalValidatorsList;
        uint256[] timestamps;
        bytes[][] proofsArray;
        address[] updateAuthorities;
    }

    struct FuzzTestData {
        address[] strategies;
        uint256[] ppss;
        uint256[] validatorSets;
        uint256[] totalValidatorsList;
        uint256[] timestamps;
        bytes[][] proofsArray;
        uint256 totalGasNeeded;
        uint256 estimatedProcessingGas;
        uint256 minimumGasToReachCheck;
        uint256 estimatedGasAtCheck;
        bool shouldTriggerGasCheck;
    }

    function test_BatchUpdatePPS_Success() public {
        BatchTestData memory data;
        
        // Create two strategies and valid proofs for them
        data.strategy1 = address(svStrategy);

        (, data.strategy2,) = aggregatorSuperVault.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                name: "Secondary TestVault",
                symbol: "STV",
                mainManager: mockManager,
                secondaryManagers: new address[](0),
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({ performanceFeeBps: 1000, managementFeeBps: 0, recipient: TREASURY }),
                maxUnpauseTimeLock: 0
            })
        );

        vm.warp(block.timestamp + 1 days);

        data.strategies = new address[](2);
        data.strategies[0] = data.strategy1;
        data.strategies[1] = data.strategy2;

        data.ppss = new uint256[](2);
        data.ppss[0] = PPS;
        data.ppss[1] = PPS * 2;


        data.validatorSets = new uint256[](2);
        data.validatorSets[0] = 2;
        data.validatorSets[1] = 2;

        data.totalValidatorsList = new uint256[](2);
        data.totalValidatorsList[0] = 3;
        data.totalValidatorsList[1] = 3;

        data.timestamps = new uint256[](2);
        data.timestamps[0] = block.timestamp;
        data.timestamps[1] = block.timestamp;

        data.proofsArray = new bytes[][](2);
        data.proofsArray[0] = _createValidProofs(
            data.strategy1, data.ppss[0], data.timestamps[0], new uint256[](0)
        );
        data.proofsArray[1] = _createValidProofs(
            data.strategy2, data.ppss[1], data.timestamps[1], new uint256[](0)
        );

        data.updateAuthorities = new address[](2);
        data.updateAuthorities[0] = user;
        data.updateAuthorities[1] = user;

        // Call batchUpdatePPS
        vm.prank(user);
        oracleECDSA.updatePPS(
            IECDSAPPSOracle.UpdatePPSArgs({
                strategies: data.strategies,
                proofsArray: data.proofsArray,
                ppss: data.ppss,
                timestamps: data.timestamps
            })
        );

        // Test passes if no revert occurs
    }

    function test_BatchUpdatePPS_InsufficientGasForForward() public {
        BatchTestData memory data;
        
        // Create two strategies and valid proofs for them
        data.strategy1 = address(svStrategy);

        (, data.strategy2,) = aggregatorSuperVault.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                name: "Secondary TestVault",
                symbol: "STV",
                mainManager: mockManager,
                secondaryManagers: new address[](0),
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({ performanceFeeBps: 1000, managementFeeBps: 0, recipient: TREASURY }),
                maxUnpauseTimeLock: 0
            })
        );

        vm.warp(block.timestamp + 1 days);

        data.strategies = new address[](2);
        data.strategies[0] = data.strategy1;
        data.strategies[1] = data.strategy2;

        data.ppss = new uint256[](2);
        data.ppss[0] = PPS;
        data.ppss[1] = PPS * 2;


        data.validatorSets = new uint256[](2);
        data.validatorSets[0] = 2;
        data.validatorSets[1] = 2;

        data.totalValidatorsList = new uint256[](2);
        data.totalValidatorsList[0] = 3;
        data.totalValidatorsList[1] = 3;

        data.timestamps = new uint256[](2);
        data.timestamps[0] = block.timestamp;
        data.timestamps[1] = block.timestamp;

        data.proofsArray = new bytes[][](2);
        data.proofsArray[0] = _createValidProofs(
            data.strategy1, data.ppss[0], data.timestamps[0], new uint256[](0)
        );
        data.proofsArray[1] = _createValidProofs(
            data.strategy2, data.ppss[1], data.timestamps[1], new uint256[](0)
        );

        // Set an extremely high gas cost per strategy to trigger the insufficient gas check
        // This will cause totalGas = count * gasInfo to be very high
        vm.startPrank(governorAddress);
        governor.setGasInfo(address(oracleECDSA), 1_000_000_000_000); // Set very high gas cost
        vm.stopPrank();

        // Expect the InsufficientGasForForward event to be emitted
        vm.expectEmit(false, false, false, false);
        emit IECDSAPPSOracle.InsufficientGasForForward(0, 0); // We don't check exact values since they depend on gas left

        // Call batchUpdatePPS with limited gas - should trigger the gas check and emit the event
        // With 2 strategies and 1_000_000_000_000 gas per strategy, totalGas = 2_000_000_000_000
        // We need to call with less gas than totalGas + gasleft() / 64
        vm.prank(user);
        oracleECDSA.updatePPS{gas: 1_000_000}( // Use low gas limit to trigger the check
            IECDSAPPSOracle.UpdatePPSArgs({
                strategies: data.strategies,
                proofsArray: data.proofsArray,
                ppss: data.ppss,
                timestamps: data.timestamps
            })
        );
    }

    // The following test tries to discover the gas amount to broke the 63/64 rule
    // Code changes can affect it
    // TODO: Uncomment this test before code freeze
    /// @notice Fuzz test for insufficient gas check with varying parameters
    // function testFuzz_BatchUpdatePPS_InsufficientGasForForward(
    //     uint8 strategyCount_,
    //     uint32 gasLimit_,
    //     uint64 gasPerStrategy_
    // ) public {
    //     // Bound inputs to reasonable ranges
    //     strategyCount_ = uint8(bound(strategyCount_, 1, 3)); // Reduce max strategies to avoid complexity
    //     gasLimit_ = uint32(bound(gasLimit_, 500_000, 5_000_000)); // Higher minimum to avoid OOG
    //     gasPerStrategy_ = uint64(bound(gasPerStrategy_, 100_000, 1_000_000_000)); // More reasonable range

    //     FuzzTestData memory data;
        
    //     // Create strategies array
    //     data.strategies = new address[](strategyCount_);
    //     data.strategies[0] = address(svStrategy);
        
    //     // Create additional strategies if needed
    //     for (uint256 i = 1; i < strategyCount_; i++) {
    //         (, address newStrategy,) = aggregatorSuperVault.createVault(
    //             ISuperVaultAggregator.VaultCreationParams({
    //                 asset: address(asset),
    //                 name: string(abi.encodePacked("FuzzVault", vm.toString(i))),
    //                 symbol: string(abi.encodePacked("FV", vm.toString(i))),
    //                 mainManager: mockManager,
    //                 secondaryManagers: new address[](0),
    //                 minUpdateInterval: 5,
    //                 maxStaleness: 300,
    //                 feeConfig: ISuperVaultStrategy.FeeConfig({ 
    //                     performanceFeeBps: 1000, 
    //                     managementFeeBps: 0, 
    //                     recipient: TREASURY 
    //                 }),
    //                 maxUnpauseTimeLock: 0
    //             })
    //         );
    //         data.strategies[i] = newStrategy;
    //     }

    //     vm.warp(block.timestamp + 1 days);

    //     // Initialize arrays
    //     data.ppss = new uint256[](strategyCount_);
    //     data.validatorSets = new uint256[](strategyCount_);
    //     data.totalValidatorsList = new uint256[](strategyCount_);
    //     data.timestamps = new uint256[](strategyCount_);
    //     data.proofsArray = new bytes[][](strategyCount_);

    //     // Fill arrays with test data
    //     for (uint256 i = 0; i < strategyCount_; i++) {
    //         data.ppss[i] = PPS * (i + 1);
    //         data.validatorSets[i] = 2;
    //         data.totalValidatorsList[i] = 3;
    //         data.timestamps[i] = block.timestamp;
            
    //         data.proofsArray[i] = _createValidProofs(
    //             data.strategies[i], 
    //             data.ppss[i], 
 
    //             data.validatorSets[i], 
    //             data.totalValidatorsList[i], 
    //             data.timestamps[i], 
    //             new uint256[](0)
    //         );
    //     }

    //     // Set the gas cost per strategy
    //     vm.startPrank(governorAddress);
    //     governor.setGasInfo(address(oracleECDSA), gasPerStrategy_);
    //     vm.stopPrank();

    //     // Calculate gas parameters
    //     data.totalGasNeeded = uint256(strategyCount_) * uint256(gasPerStrategy_);
    //     data.estimatedProcessingGas = strategyCount_ * 150_000; // Conservative estimate per strategy
    //     data.minimumGasToReachCheck = data.estimatedProcessingGas + 50_000; // Buffer for reaching the check
        
    //     vm.prank(user);
        
    //     // Only test the gas check if we have enough gas to reach it
    //     if (gasLimit_ >= data.minimumGasToReachCheck) {
    //         // Calculate if the gas check should trigger
    //         data.estimatedGasAtCheck = gasLimit_ > data.estimatedProcessingGas ? gasLimit_ - data.estimatedProcessingGas : 0;
    //         data.shouldTriggerGasCheck = (data.estimatedGasAtCheck * 63) / 64 <= data.totalGasNeeded;
            
    //         if (data.shouldTriggerGasCheck) {
    //             // Expect the InsufficientGasForForward event
    //             vm.expectEmit(false, false, false, false);
    //             emit IECDSAPPSOracle.InsufficientGasForForward(0, 0);
    //         }
            
    //         // Call with the specified gas limit
    //         oracleECDSA.updatePPS{gas: gasLimit_}(
    //             IECDSAPPSOracle.UpdatePPSArgs({
    //                 strategies: data.strategies,
    //                 proofsArray: data.proofsArray,
    //                 ppss: data.ppss,
    //     //                 validatorSets: data.validatorSets,
    //                 totalValidators: data.totalValidatorsList,
    //                 timestamps: data.timestamps
    //             })
    //         );
    //     } else {
    //         // Skip this test case as it would cause OOG before reaching the gas check
    //         vm.expectRevert();
    //         oracleECDSA.updatePPS{gas: gasLimit_}(
    //             IECDSAPPSOracle.UpdatePPSArgs({
    //                 strategies: data.strategies,
    //                 proofsArray: data.proofsArray,
    //                 ppss: data.ppss,
    //     //                 validatorSets: data.validatorSets,
    //                 totalValidators: data.totalValidatorsList,
    //                 timestamps: data.timestamps
    //             })
    //         );
    //     }
    // }

    function test_BatchUpdatePPS_EmptyArrayReverts() public {
        // Create empty arrays
        address[] memory strategies = new address[](0);
        bytes[][] memory proofsArray = new bytes[][](0);
        uint256[] memory ppss = new uint256[](0);
        // Note: validatorSets and totalValidators are no longer needed for UpdatePPSArgs
        uint256[] memory timestamps = new uint256[](0);

        // Call should revert because arrays are empty
        vm.prank(user);
        vm.expectRevert(IECDSAPPSOracle.ZERO_LENGTH_ARRAY.selector);
        oracleECDSA.updatePPS(
            IECDSAPPSOracle.UpdatePPSArgs({
                strategies: strategies,
                proofsArray: proofsArray,
                ppss: ppss,
                timestamps: timestamps
            })
        );
    }

    struct BatchMismatchTestData {
        address[] strategies;
        bytes[][] proofsArray;
        uint256[] ppss;
        uint256[] validatorSets;
        uint256[] totalValidatorsList;
        uint256[] timestamps;
        address[] updateAuthorities;
    }

    function test_BatchUpdatePPS_ArrayLengthMismatchReverts() public {
        BatchMismatchTestData memory data;
        
        // Create arrays with mismatched lengths
        data.strategies = new address[](2);
        data.strategies[0] = address(0x111);
        data.strategies[1] = address(0x222);

        data.proofsArray = new bytes[][](1); // Only one proof set
        data.proofsArray[0] = _createValidProofs(data.strategies[0], PPS, block.timestamp, new uint256[](0));

        data.ppss = new uint256[](2);
        data.ppss[0] = PPS;
        data.ppss[1] = PPS * 2;


        data.validatorSets = new uint256[](2);
        data.validatorSets[0] = 2;
        data.validatorSets[1] = 2;

        data.totalValidatorsList = new uint256[](2);
        data.totalValidatorsList[0] = 3;
        data.totalValidatorsList[1] = 3;

        data.timestamps = new uint256[](2);
        data.timestamps[0] = block.timestamp;
        data.timestamps[1] = block.timestamp;

        data.updateAuthorities = new address[](2);
        data.updateAuthorities[0] = user;
        data.updateAuthorities[1] = user;

        // Call should revert because proofsArray length doesn't match strategies length
        vm.prank(user);
        vm.expectRevert(IECDSAPPSOracle.ARRAY_LENGTH_MISMATCH.selector);
        oracleECDSA.updatePPS(
            IECDSAPPSOracle.UpdatePPSArgs({
                strategies: data.strategies,
                proofsArray: data.proofsArray,
                ppss: data.ppss,
                timestamps: data.timestamps
            })
        );
    }

    struct BatchValidationTestData {
        address strategy1;
        address strategy2;
        address[] strategies;
        uint256[] ppss;
        uint256[] validatorSets;
        uint256[] totalValidatorsList;
        uint256[] timestamps;
        bytes[][] proofsArray;
        address[] updateAuthorities;
    }

    function test_BatchUpdatePPS_ValidationFailureReverts() public {
        BatchValidationTestData memory data;
        
        // Create two strategies
        data.strategy1 = address(0x111);
        data.strategy2 = address(0x222);

        data.strategies = new address[](2);
        data.strategies[0] = data.strategy1;
        data.strategies[1] = data.strategy2;

        data.ppss = new uint256[](2);
        data.ppss[0] = PPS;
        data.ppss[1] = PPS * 2;


        data.validatorSets = new uint256[](2);
        data.validatorSets[0] = 2;
        data.validatorSets[1] = 2;

        data.totalValidatorsList = new uint256[](2);
        data.totalValidatorsList[0] = 3;
        data.totalValidatorsList[1] = 3;

        data.timestamps = new uint256[](2);
        data.timestamps[0] = block.timestamp;
        data.timestamps[1] = block.timestamp;

        data.updateAuthorities = new address[](2);
        data.updateAuthorities[0] = user;
        data.updateAuthorities[1] = user;

        // First strategy has valid proofs
        data.proofsArray = new bytes[][](2);
        data.proofsArray[0] = _createValidProofs(
            data.strategy1, data.ppss[0], data.timestamps[0], new uint256[](0)
        );

        // Second strategy has empty proofs array (should trigger ZERO_LENGTH_ARRAY error)
        data.proofsArray[1] = new bytes[](0);

        // Expect the ProofValidationFailed event to be emitted for the second strategy
        vm.expectEmit(true, false, false, false);
        emit IECDSAPPSOracle.ProofValidationFailedLowLevel(data.strategy2, "ZERO_LENGTH_ARRAY()");

        // Call should not revert but emit validation failure event
        vm.prank(user);
        oracleECDSA.updatePPS(
            IECDSAPPSOracle.UpdatePPSArgs({
                strategies: data.strategies,
                proofsArray: data.proofsArray,
                ppss: data.ppss,
                timestamps: data.timestamps
            })
        );
    }

    /*//////////////////////////////////////////////////////////////
                        INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/
    function test_UpdateSuperVaultPPS_Integration() public {
        // Set the VALIDATOR_KEY from the BaseSuperVaultTest as a valid validator
        vm.startPrank(governorAddress);
        governor.addValidator(vm.addr(VALIDATOR_KEY));
        governor.setPPSOracleQuorum(1); // Only need one validator

        governor.proposeActivePPSOracle(address(oracleECDSA));
        vm.warp(block.timestamp + 7 days);
        governor.executeActivePPSOracleChange();

        vm.stopPrank();

        // Update the PPS using the helper function
        uint256 updatedPPS = _updateSuperVaultPPS(address(strategy), address(vault));

        // Test passes if no revert occurs
        assertEq(updatedPPS, 1e6);
    }

    /**
     * @notice Creates valid proofs for the ECDSAPPSOracle
     * @param strategy_ The address of the strategy
     * @param pps The price per share
     * @param timestamp The timestamp of the PPS update
     * @param specificSignerKeys An optional array of specific signer keys to use
     * @return proofs An array of valid proofs
     */
    function _createValidProofs(
        address strategy_,
        uint256 pps,
        uint256 timestamp,
        uint256[] memory specificSignerKeys
    )
        internal
        view
        returns (bytes[] memory)
    {
        // Create digest with all parameters (updated for simplified typehash)
        bytes32 structHash = keccak256(
            abi.encodePacked(
                oracleECDSA.UPDATE_PPS_TYPEHASH(),
                strategy_,
                pps,
                timestamp,
                oracleECDSA.noncePerStrategy(address(svStrategy))
            )
        );
        bytes32 domainSeparator = oracleECDSA.domainSeparator();
        bytes32 digest = MessageHashUtils.toTypedDataHash(domainSeparator, structHash);

        // If specific signer keys are provided, use them; otherwise, use default validators
        uint256[] memory signerKeys;
        if (specificSignerKeys.length > 0) {
            signerKeys = specificSignerKeys;
        } else {
            // Use 2 validators by default (matching the quorum setting in setUp)
            signerKeys = new uint256[](2);
            signerKeys[0] = validator1PrivateKey;
            signerKeys[1] = validator2PrivateKey;
        }

        // Sort signer keys by their corresponding addresses to ensure ascending order
        _sortSignerKeysByAddress(signerKeys);

        // Create proofs array
        bytes[] memory proofs = new bytes[](signerKeys.length);
        for (uint256 i = 0; i < signerKeys.length; i++) {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKeys[i], digest);
            proofs[i] = abi.encodePacked(r, s, v);
        }

        return proofs;
    }

    /// @notice Sorts signer keys by their corresponding addresses in ascending order
    /// @param signerKeys Array of private keys to sort
    function _sortSignerKeysByAddress(uint256[] memory signerKeys) internal pure {
        uint256 length = signerKeys.length;
        
        // Simple bubble sort - sufficient for small arrays in tests
        for (uint256 i = 0; i < length - 1; i++) {
            for (uint256 j = 0; j < length - i - 1; j++) {
                address addr1 = vm.addr(signerKeys[j]);
                address addr2 = vm.addr(signerKeys[j + 1]);
                
                if (addr1 > addr2) {
                    // Swap
                    uint256 temp = signerKeys[j];
                    signerKeys[j] = signerKeys[j + 1];
                    signerKeys[j + 1] = temp;
                }
            }
        }
    }
}
