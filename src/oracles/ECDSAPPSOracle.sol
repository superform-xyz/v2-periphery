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
    mapping(address _strategy => uint256 _nonce) public noncePerStrategy;

    /// @notice The SuperGovernor contract for validator verification
    ISuperGovernor public immutable SUPER_GOVERNOR;
    bytes32 public constant UPDATE_PPS_TYPEHASH = keccak256(
        "UpdatePPS(address strategy,uint256 pps,uint256 ppsStdev,uint256 validatorSet,uint256 totalValidators,uint256 timestamp, uint256 strategyNonce)"
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
        uint256 strategiesLength = args.strategies.length;
        
        if (strategiesLength == 0) revert ZERO_LENGTH_ARRAY();
        // Validate input array lengths
        if (    strategiesLength != args.proofsArray.length
                || strategiesLength != args.ppss.length
                || strategiesLength != args.ppsStdevs.length || strategiesLength != args.validatorSets.length
                || strategiesLength != args.timestamps.length || strategiesLength != args.totalValidators.length
        ) revert ARRAY_LENGTH_MISMATCH();


        // Process strategies and collect valid entries
        (
            address[] memory validStrategies,
            uint256[] memory validPpss,
            uint256[] memory validPpsStdevs,
            uint256[] memory validValidatorSets,
            uint256[] memory validTotalValidators,
            uint256[] memory validTimestamps
        ) = _processBatchStrategies(args, strategiesLength);

        // Forward valid entries if any exist
        _forwardValidEntries(
            validStrategies,
            validPpss,
            validPpsStdevs,
            validValidatorSets,
            validTotalValidators,
            validTimestamps
        );
    }

    

    /// @notice Validates an array of proofs for a strategy's PPS update
    /// @param params Validation parameters
    /// @dev Reverts immediately if duplicate signers are found or quorum is not met
    function validateProofs(IECDSAPPSOracle.ValidationParams memory params)
        public
        view
    {
        _validateProofs(params);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Validates an array of proofs for a strategy's PPS update
    /// @param params Validation parameters
    /// @dev Reverts immediately if duplicate signers are found or quorum is not met
    function _validateProofs(IECDSAPPSOracle.ValidationParams memory params) internal view {
        // Check if this oracle is the active PPS Oracle
        if (!SUPER_GOVERNOR.isActivePPSOracle(address(this))) revert NOT_ACTIVE_PPS_ORACLE();

        // Create message hash with all parameters- If anyare incorrect, the message hash will be different and the
        // derived signer address will be incorrect- resulting in a revert
        bytes32 structHash = keccak256(
            abi.encodePacked(
                UPDATE_PPS_TYPEHASH,
                params.strategy,
                params.pps,
                params.ppsStdev,
                params.validatorSet,
                params.totalValidators,
                params.timestamp,
                noncePerStrategy[params.strategy]
            )
        );
        bytes32 digest = _hashTypedDataV4(structHash);
        
        uint256 proofsLength = params.proofs.length;
        if (proofsLength == 0) revert ZERO_LENGTH_ARRAY();

        address lastSigner;
        // Process each proof
        for (uint256 i; i < proofsLength; i++) {
            // Recover the signer from the proof
            address signer = ECDSA.recover(digest, params.proofs[i]);

            // Verify the signer is a registered validator
            if (!SUPER_GOVERNOR.isValidator(signer)) revert INVALID_VALIDATOR();

            // Check for duplicates or improper ordering - signers must be in ascending order
            if (signer <= lastSigner) revert INVALID_PROOF();
            lastSigner = signer;
        }

        // Validate that validatorSet matches actual number of valid signatures
        if (params.validatorSet != proofsLength) revert INVALID_VALIDATOR_SET();

        // Validate that totalValidators matches actual total number of validators
        if (params.totalValidators != SUPER_GOVERNOR.getValidators().length) revert INVALID_TOTAL_VALIDATORS();

        // Ensure we have enough valid signatures to meet quorum
        if (proofsLength < SUPER_GOVERNOR.getPPSOracleQuorum()) revert QUORUM_NOT_MET();
    }

    /// @notice Processes batch strategies and returns valid entries
    /// @param args Batch update arguments
    /// @param strategiesLength Length of strategies array
    /// @return validStrategies Array of valid strategy addresses
    /// @return validPpss Array of valid PPS values
    /// @return validPpsStdevs Array of valid PPS standard deviations
    /// @return validValidatorSets Array of valid validator sets
    /// @return validTotalValidators Array of valid total validators
    /// @return validTimestamps Array of valid timestamps
    function _processBatchStrategies(
        UpdatePPSArgs calldata args,
        uint256 strategiesLength
    )
        internal
        returns (
            address[] memory validStrategies,
            uint256[] memory validPpss,
            uint256[] memory validPpsStdevs,
            uint256[] memory validValidatorSets,
            uint256[] memory validTotalValidators,
            uint256[] memory validTimestamps
        )
    {
        // Arrays to collect valid entries
        validStrategies = new address[](strategiesLength);
        validPpss = new uint256[](strategiesLength);
        validPpsStdevs = new uint256[](strategiesLength);
        validValidatorSets = new uint256[](strategiesLength);
        validTotalValidators = new uint256[](strategiesLength);
        validTimestamps = new uint256[](strategiesLength);
        uint256 validCount;

        // Process each strategy update
        for (uint256 i; i < strategiesLength; i++) {
            bool isValid = _processIndividualStrategy(args, i);
            if (isValid) {
                // Add to valid entries
                validStrategies[validCount] = args.strategies[i];
                validPpss[validCount] = args.ppss[i];
                validPpsStdevs[validCount] = args.ppsStdevs[i];
                validValidatorSets[validCount] = args.validatorSets[i];
                validTotalValidators[validCount] = args.totalValidators[i];
                validTimestamps[validCount] = args.timestamps[i];
                validCount++;
            }
        }

        // Resize arrays to actual valid count
        assembly {
            mstore(validStrategies, validCount)
            mstore(validPpss, validCount)
            mstore(validPpsStdevs, validCount)
            mstore(validValidatorSets, validCount)
            mstore(validTotalValidators, validCount)
            mstore(validTimestamps, validCount)
        }
    }

    /// @notice Processes an individual strategy in the batch
    /// @param args Batch update arguments
    /// @param index Index of the strategy to process
    /// @return isValid True if the strategy was processed successfully
    function _processIndividualStrategy(
        UpdatePPSArgs calldata args,
        uint256 index
    ) internal returns (bool isValid) {
        address _strategy = args.strategies[index];

         // Validate proofs and check quorum requirement
        try IECDSAPPSOracle(address(this)).validateProofs(
            IECDSAPPSOracle.ValidationParams({
                strategy: _strategy,
                proofs: args.proofsArray[index],
                pps: args.ppss[index],
                ppsStdev: args.ppsStdevs[index],
                validatorSet: args.validatorSets[index],
                totalValidators: args.totalValidators[index],
                timestamp: args.timestamps[index]
            })
        ) {
            emit PPSValidated(
                _strategy,
                args.ppss[index],
                args.ppsStdevs[index],
                args.validatorSets[index],
                args.totalValidators[index],
                args.timestamps[index],
                msg.sender
            );
        } catch Error(string memory reason) {
            emit ProofValidationFailed(_strategy, reason);
            return false;
        } catch (bytes memory lowLevelData) {
            emit ProofValidationFailedLowLevel(_strategy, lowLevelData);
            return false;
        }
        
        noncePerStrategy[_strategy]++;
        return true;
    }

    /// @notice Forwards valid entries to SuperVaultAggregator
    /// @param validStrategies Array of valid strategy addresses
    /// @param validPpss Array of valid PPS values
    /// @param validPpsStdevs Array of valid PPS standard deviations
    /// @param validValidatorSets Array of valid validator sets
    /// @param validTotalValidators Array of valid total validators
    /// @param validTimestamps Array of valid timestamps
    function _forwardValidEntries(
        address[] memory validStrategies,
        uint256[] memory validPpss,
        uint256[] memory validPpsStdevs,
        uint256[] memory validValidatorSets,
        uint256[] memory validTotalValidators,
        uint256[] memory validTimestamps
    ) internal {
        // Only forward if there are valid entries
        if (validStrategies.length > 0) {
            try ISuperVaultAggregator(SUPER_GOVERNOR.getAddress(SUPER_VAULT_AGGREGATOR)).forwardPPS(
                ISuperVaultAggregator.ForwardPPSArgs({
                    strategies: validStrategies,
                    ppss: validPpss,
                    ppsStdevs: validPpsStdevs,
                    validatorSets: validValidatorSets,
                    totalValidators: validTotalValidators,
                    timestamps: validTimestamps,
                    updateAuthority: msg.sender
                })
            ) {
            } catch Error(string memory reason) {
                emit BatchForwardPPSFailed(reason);
            } catch (bytes memory lowLevelData) {
                emit BatchForwardPPSFailedLowLevel(lowLevelData);
            }
        }
    }

}
