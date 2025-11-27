// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

/// @title ECDSAPPSOracle
/// @author Superform Labs
/// @notice Interface for PPS oracles that provide price-per-share updates
/// @dev All PPS oracle implementations must conform to this interface
interface IECDSAPPSOracle {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @notice Thrown when the proof is invalid or cannot be verified
    error INVALID_PROOF();
    /// @notice Thrown when a validator is not registered or authorized
    error INVALID_VALIDATOR();
    /// @notice Thrown when the quorum of validators is not met
    error QUORUM_NOT_MET();
    /// @notice Thrown when the input arrays have different lengths
    error ARRAY_LENGTH_MISMATCH();
    /// @notice Thrown when the input array is empty
    error ZERO_LENGTH_ARRAY();
    /// @notice Thrown when the timestamp in the proof is invalid
    error INVALID_TIMESTAMP();
    /// @notice Thrown when the deviation from previous PPS is too high
    error HIGH_PPS_DEVIATION();
    /// @notice Thrown when the totalValidators doesn't match the actual total number of validators
    error INVALID_TOTAL_VALIDATORS();
    /// @notice Thrown when the gas provided is insufficient for external calls
    error INSUFFICIENT_GAS_FOR_EXTERNAL_CALL();
    /// @notice Thrown when the number of strategies exceeds the maximum allowed
    error MAX_STRATEGIES_EXCEEDED();
    /// @notice Thrown when strategies are not sorted in ascending order or contain duplicates
    error STRATEGIES_NOT_SORTED_UNIQUE();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when a PPS update is validated and forwarded
    /// @param strategy Address of the strategy
    /// @param pps The validated price-per-share value
    /// @param timestamp Timestamp when the value was generated
    /// @param sender Address that submitted the update
    event PPSValidated(address indexed strategy, uint256 pps, uint256 timestamp, address indexed sender);

    /// @notice Emitted when proof validation failed
    /// @param strategy Address of the strategy
    /// @param reason Revert reason
    event ProofValidationFailed(address indexed strategy, string reason);

    /// @notice Emitted when proof validation failed
    /// @param strategy Address of the strategy
    /// @param data Revert encoded data
    event ProofValidationFailedLowLevel(address indexed strategy, bytes data);

    /// @notice Emitted when batch forward PPS failed
    /// @param reason Revert reason
    event BatchForwardPPSFailed(string reason);

    /// @notice Emitted when batch forward PPS failed
    /// @param lowLevelData Revert encoded data
    event BatchForwardPPSFailedLowLevel(bytes lowLevelData);

    /*//////////////////////////////////////////////////////////////
                            STRUCTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Parameters for validating PPS proofs
    /// @param strategy Address of the strategy
    /// @param proofs Array of cryptographic proofs
    /// @param pps Price-per-share value
    /// @param timestamp Timestamp when the value was generated
    struct ValidationParams {
        address strategy;
        bytes[] proofs;
        uint256 pps;
        uint256 timestamp;
    }

    /// @notice Arguments for batch updating PPS for multiple strategies
    /// @param strategies Array of strategy addresses
    /// @param proofsArray Array of arrays of cryptographic proofs (one array of proofs per strategy)
    /// @param ppss Array of price-per-share values
    /// @param timestamps The time and therefore the blockchain(s) state(s) (plural important) this PPS refers to
    struct UpdatePPSArgs {
        address[] strategies;
        bytes[][] proofsArray;
        uint256[] ppss;
        uint256[] timestamps;
    }

    /// @notice Struct to avoid stack too deep errors in batch processing
    struct ValidatedBatchData {
        address[] strategies;
        uint256[] ppss;
        uint256[] timestamps;
        uint256[] validatorSets;
    }

    /*//////////////////////////////////////////////////////////////
                              VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns the current nonce
    /// @param strategy_ Address of the strategy
    /// @return The current nonce
    function noncePerStrategy(address strategy_) external view returns (uint256);

    /// @notice Returns the EIP-712 domain separator for this contract
    /// @return The domain separator used for signature validation
    /// @dev The domain separator is derived from:
    ///      - Contract name (set in constructor)
    ///      - Contract version (set in constructor)
    ///      - Chain ID (from block.chainid)
    ///      - Contract address (address(this))
    ///      Off-chain signers MUST use this exact domain separator when creating signatures.
    ///      The domain separator is computed on-demand using EIP-712's _domainSeparatorV4(),
    ///      which handles chain ID changes (e.g., after hard forks).
    ///      See EIP-712 specification: https://eips.ethereum.org/EIPS/eip-712
    function domainSeparator() external view returns (bytes32);

    /// @notice Returns the signature typehash
    /// @return The typehash
    function UPDATE_PPS_TYPEHASH() external view returns (bytes32);

    /// @notice Validates an array of proofs for a strategy's PPS update
    /// @param params Validation parameters
    function validateProofs(IECDSAPPSOracle.ValidationParams memory params) external view;

    /// @notice Validates an array of proofs for a strategy's PPS update
    /// @param params Validation parameters
    /// @param requiredQuorum Required quorum for validation
    function validateProofs(IECDSAPPSOracle.ValidationParams memory params, uint256 requiredQuorum) external view;

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Updates the PPS for multiple strategies in a batch
    /// @param args Struct containing all parameters for batch PPS update
    function updatePPS(UpdatePPSArgs calldata args) external;
}
