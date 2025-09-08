// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

// External
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

// Superform
import { ISuperGovernor } from "../interfaces/ISuperGovernor.sol";
import { ISuperVaultAggregator } from "../interfaces/SuperVault/ISuperVaultAggregator.sol";
import { IECDSAPPSOracle } from "../interfaces/oracles/IECDSAPPSOracle.sol";

/// @title ECDSAPPSOracle
/// @author Superform Labs
/// @notice PPS Oracle that validates price updates using ECDSA signatures
/// @dev Implements the IECDSAPPSOracle interface for validating and forwarding PPS updates
contract ECDSAPPSOracle is IECDSAPPSOracle, EIP712 {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/
    uint256 public nonce;

    /// @notice The SuperGovernor contract for validator verification
    ISuperGovernor public immutable SUPER_GOVERNOR;
    bytes32 public constant UPDATE_PPS_TYPEHASH = keccak256(
        "UpdatePPS(address submitter, address strategy,uint256 pps,uint256 ppsStdev,uint256 validatorSet,uint256 totalValidators,uint256 timestamp, uint256 nonce)"
    );

    bytes32 private constant SUPER_VAULT_AGGREGATOR = keccak256("SUPER_VAULT_AGGREGATOR");

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @notice Initializes the ECDSAPPSOracle contract
    /// @param superGovernor_ Address of the SuperGovernor contract
    constructor(address superGovernor_, string memory name_, string memory version_) EIP712(name_, version_) {
        if (superGovernor_ == address(0)) revert INVALID_VALIDATOR();

        SUPER_GOVERNOR = ISuperGovernor(superGovernor_);
    }

    /*//////////////////////////////////////////////////////////////
                              VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IECDSAPPSOracle
    function domainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /*//////////////////////////////////////////////////////////////
                         PPS UPDATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IECDSAPPSOracle
    function updatePPS(UpdatePPSArgs calldata args) external {
        // Validate proofs and check quorum requirement
        _validateProofs(
            msg.sender, args.strategy, args.proofs, args.pps, args.ppsStdev, args.validatorSet, args.totalValidators, args.timestamp
        );
        nonce++;

        // Emit event that PPS has been validated
        emit PPSValidated(
            args.strategy, args.pps, args.ppsStdev, args.validatorSet, args.totalValidators, args.timestamp, msg.sender
        );

        // Forward the validated PPS update to the SuperVaultAggregator
        // The msg.sender is passed as updateAuthority for upkeep tracking
        ISuperVaultAggregator.ForwardPPSArgs memory forwardArgs = ISuperVaultAggregator.ForwardPPSArgs({
            strategy: args.strategy,
            isExempt: false, // This will be determined by SuperVaultAggregator
            pps: args.pps,
            ppsStdev: args.ppsStdev,
            validatorSet: args.validatorSet,
            totalValidators: args.totalValidators,
            timestamp: args.timestamp,
            upkeepCost: 0 // This will be set by SuperVaultAggregator
         });

        ISuperVaultAggregator(SUPER_GOVERNOR.getAddress(SUPER_VAULT_AGGREGATOR)).forwardPPS(msg.sender, forwardArgs);
    }

    /// @inheritdoc IECDSAPPSOracle
    function batchUpdatePPS(BatchUpdatePPSArgs calldata args) external {
        uint256 strategiesLength = args.strategies.length;

        if (strategiesLength == 0) revert ZERO_LENGTH_ARRAY();
        // Validate input array lengths
        if (
            strategiesLength != args.proofsArray.length || strategiesLength != args.ppss.length
                || strategiesLength != args.ppsStdevs.length || strategiesLength != args.validatorSets.length
                || strategiesLength != args.timestamps.length || strategiesLength != args.totalValidators.length
        ) revert ARRAY_LENGTH_MISMATCH();

        // Process each strategy update
        for (uint256 i; i < strategiesLength; i++) {
            _validateProofs(
                msg.sender,
                args.strategies[i],
                args.proofsArray[i],
                args.ppss[i],
                args.ppsStdevs[i],
                args.validatorSets[i],
                args.totalValidators[i],
                args.timestamps[i]
            );
            emit PPSValidated(
                args.strategies[i],
                args.ppss[i],
                args.ppsStdevs[i],
                args.validatorSets[i],
                args.totalValidators[i],
                args.timestamps[i],
                msg.sender
            );
        }
        nonce++;

        ISuperVaultAggregator(SUPER_GOVERNOR.getAddress(SUPER_VAULT_AGGREGATOR)).batchForwardPPS(
            ISuperVaultAggregator.BatchForwardPPSArgs({
                strategies: args.strategies,
                ppss: args.ppss,
                ppsStdevs: args.ppsStdevs,
                validatorSets: args.validatorSets,
                totalValidators: args.totalValidators,
                timestamps: args.timestamps
            })
        );
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Validates an array of proofs for a strategy's PPS update
    /// @param submitter Address of the submitter
    /// @param strategy Address of the strategy
    /// @param proofs Array of cryptographic proofs
    /// @param pps Price-per-share value (mean)
    /// @param ppsStdev Standard deviation of the price-per-share
    /// @param validatorSet Number of validators who calculated this PPS
    /// @param totalValidators Total number of validators in the network
    /// @param timestamp Timestamp when the value was generated
    /// @dev Reverts immediately if duplicate signers are found or quorum is not met
    function _validateProofs(
        address submitter,
        address strategy,
        bytes[] calldata proofs,
        uint256 pps,
        uint256 ppsStdev,
        uint256 validatorSet,
        uint256 totalValidators,
        uint256 timestamp
    )
        internal
        view
    {
        // Check if this oracle is the active PPS Oracle
        if (!SUPER_GOVERNOR.isActivePPSOracle(address(this))) revert NOT_ACTIVE_PPS_ORACLE();

        // Create message hash with all parameters- If anyare incorrect, the message hash will be different and the
        // derived signer address will be incorrect- resulting in a revert
        bytes32 structHash = keccak256(
            abi.encodePacked(
                UPDATE_PPS_TYPEHASH,
                submitter,
                strategy,
                pps,
                ppsStdev,
                validatorSet,
                totalValidators,
                timestamp,
                nonce
            )
        );
        bytes32 digest = _hashTypedDataV4(structHash);

        uint256 proofsLength = proofs.length;
        address lastSigner;

        if (proofsLength == 0) revert ZERO_LENGTH_ARRAY();

        // Process each proof
        for (uint256 i; i < proofsLength; i++) {
            // Recover the signer from the proof
            address signer = ECDSA.recover(digest, proofs[i]);

            // Verify the signer is a registered validator
            if (!SUPER_GOVERNOR.isValidator(signer)) revert INVALID_VALIDATOR();

            // Check for duplicates or improper ordering - signers must be in ascending order
            if (signer <= lastSigner) revert INVALID_PROOF();
            lastSigner = signer;
        }

        // Validate that validatorSet matches actual number of valid signatures
        if (validatorSet != proofsLength) revert INVALID_VALIDATOR_SET();

        // Validate that totalValidators matches actual total number of validators
        uint256 actualTotalValidators = SUPER_GOVERNOR.getValidators().length;
        if (totalValidators != actualTotalValidators) revert INVALID_TOTAL_VALIDATORS();

        // Ensure we have enough valid signatures to meet quorum
        uint256 quorumRequirement = SUPER_GOVERNOR.getPPSOracleQuorum();
        if (proofsLength < quorumRequirement) revert QUORUM_NOT_MET();
    }
}
