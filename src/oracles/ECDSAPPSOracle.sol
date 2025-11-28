// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

// External
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
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

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/
    mapping(address _strategy => uint256 _nonce) public noncePerStrategy;

    // Maximum number of strategies to process in `batchForwardPPS`
    /// @notice Maximum number of strategies that can be processed in a single batch
    /// @dev Set to 300 to stay well below gas limits while allowing efficient batch updates.
    uint256 public constant MAX_STRATEGIES = 300;

    /// @notice The SuperGovernor contract for validator verification
    ISuperGovernor public immutable SUPER_GOVERNOR;

    /// @notice EIP-712 typehash for PPS update signatures
    /// @dev Defines the structure: UpdatePPS(address strategy, uint256 pps, uint256 timestamp, uint256 strategyNonce)
    ///      - strategy: The strategy contract address
    ///      - pps: The price-per-share value being signed
    ///      - timestamp: The blockchain state timestamp this PPS represents
    ///      - strategyNonce: Current nonce for this strategy (prevents replay attacks)
    ///      This typehash MUST match the off-chain signing format exactly. Changing this typehash would
    ///      invalidate all existing signatures. See Property 1 in security_properties.md for nonce details.
    bytes32 public constant UPDATE_PPS_TYPEHASH =
        keccak256("UpdatePPS(address strategy,uint256 pps,uint256 timestamp,uint256 strategyNonce)");

    bytes32 private constant SUPER_VAULT_AGGREGATOR = keccak256("SUPER_VAULT_AGGREGATOR");

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @notice Initializes the ECDSAPPSOracle contract
    /// @param superGovernor_ Address of the SuperGovernor contract
    /// @param name_ EIP-712 domain name (e.g., "SuperformOraclePPS"). Used for domain separation.
    /// @param version_ EIP-712 domain version (e.g., "1"). Must match off-chain signing version.
    /// @dev The name_ and version_ parameters define the EIP-712 domain separator and cannot be changed
    ///      after deployment. All validator signatures must be signed with matching domain parameters.
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
        if (
            strategiesLength != args.proofsArray.length || strategiesLength != args.ppss.length
                || strategiesLength != args.timestamps.length
        ) revert ARRAY_LENGTH_MISMATCH();

        if (strategiesLength > MAX_STRATEGIES) revert MAX_STRATEGIES_EXCEEDED();

        // Validate strategies are sorted and unique to prevent nonce burning
        // This prevents attackers from submitting duplicate strategies to skip nonces
        // Strategies must be in ascending order: strategies[i] < strategies[i+1]
        for (uint256 i = 1; i < strategiesLength; i++) {
            if (args.strategies[i] <= args.strategies[i - 1]) {
                revert STRATEGIES_NOT_SORTED_UNIQUE();
            }
        }

        uint256 cachedTotalValidators = SUPER_GOVERNOR.getValidatorsCount();

        // Early validation checks
        if (cachedTotalValidators == 0) revert INVALID_TOTAL_VALIDATORS();

        // Process strategies and collect valid entries
        ValidatedBatchData memory validatedData = _processBatchStrategies(args, strategiesLength);

        // Forward valid entries if any exist
        _forwardValidEntries(validatedData);
    }

    /// @inheritdoc IECDSAPPSOracle
    /// @dev Reverts immediately if duplicate signers are found or quorum is not met
    function validateProofs(IECDSAPPSOracle.ValidationParams memory params) external view {
        // derive transient values
        uint256 requiredQuorum = SUPER_GOVERNOR.getPPSOracleQuorum();

        _validateProofs(params, requiredQuorum);
    }

    /// @inheritdoc IECDSAPPSOracle
    /// @dev Reverts immediately if duplicate signers are found or quorum is not met
    function validateProofs(IECDSAPPSOracle.ValidationParams memory params, uint256 requiredQuorum) public view {
        _validateProofs(params, requiredQuorum);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Validates an array of proofs for a strategy's PPS update
    /// @dev Implements Property 1: Signature Validation & Nonce in Digest (security_properties.md)
    ///
    ///      SECURITY GUARANTEES:
    ///      1. All signatures are EIP-712 typed structured data
    ///      2. Each signature includes the current nonce for the strategy (replay protection)
    ///      3. All signers must be registered validators (checked via SUPER_GOVERNOR)
    ///      4. All signers must be unique (enforced via ascending order check)
    ///      5. Quorum requirement must be met (M validators out of N total)
    ///
    ///      SIGNATURE STRUCTURE:
    ///      digest = EIP-712(strategy, pps, timestamp, noncePerStrategy[strategy])
    ///
    ///      FAILURE MODES:
    ///      - Reverts if quorum not met (QUORUM_NOT_MET)
    ///      - Reverts if any signer is not a registered validator (INVALID_VALIDATOR)
    ///      - Reverts if duplicate signers detected (INVALID_PROOF)
    ///      - Reverts if signatures in wrong order (INVALID_PROOF)
    ///
    /// @param params Validation parameters containing strategy, proofs, pps, timestamp
    /// @param requiredQuorum Required number of validator signatures (M out of N)
    /// @dev Check for this being the active PPS Oracle already done by SuperVaultAggregator
    /// @dev Reverts immediately if duplicate signers are found or quorum is not met
    function _validateProofs(IECDSAPPSOracle.ValidationParams memory params, uint256 requiredQuorum) internal view {
        uint256 proofsLength = params.proofs.length;
        if (proofsLength == 0) revert ZERO_LENGTH_ARRAY();

        // Quorum from batch-snapshot
        if (proofsLength < requiredQuorum) revert QUORUM_NOT_MET();

        // [Property 1: Signature Validation & Nonce in Digest]
        // Build EIP-712 typed data digest that includes the current nonce for this strategy.
        // This binds the signature to a specific nonce value, preventing replay attacks.
        // Once a signature is used and the nonce increments, the same signature becomes invalid.
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encodePacked(
                    UPDATE_PPS_TYPEHASH,
                    params.strategy,
                    params.pps,
                    params.timestamp,
                    noncePerStrategy[params.strategy]
                )
            )
        );

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
    }

    /// @notice Processes batch strategies and returns valid entries
    /// @param args Batch update arguments
    /// @param strategiesLength Length of strategies array
    /// @return validatedData Struct containing all validated batch data
    function _processBatchStrategies(
        UpdatePPSArgs calldata args,
        uint256 strategiesLength
    )
        internal
        returns (ValidatedBatchData memory validatedData)
    {
        uint256 requiredQuorum = SUPER_GOVERNOR.getPPSOracleQuorum();
        uint256 validCount; // Plain local, starts at 0

        // -------- existing collection logic --------
        validatedData.strategies = new address[](strategiesLength);
        validatedData.ppss = new uint256[](strategiesLength);
        validatedData.timestamps = new uint256[](strategiesLength);
        validatedData.validatorSets = new uint256[](strategiesLength);

        for (uint256 i; i < strategiesLength; ++i) {
            bool isValid = _processIndividualStrategy(args, i, requiredQuorum);
            if (isValid) {
                validatedData.strategies[validCount] = args.strategies[i];
                validatedData.ppss[validCount] = args.ppss[i];
                validatedData.timestamps[validCount] = args.timestamps[i];
                validatedData.validatorSets[validCount] = args.proofsArray[i].length;
                unchecked {
                    ++validCount;
                }
            }
        }

        // Resize to validCount - split into separate assembly blocks to avoid stack depth issues
        assembly ("memory-safe") {
            mstore(mload(add(validatedData, 0x00)), validCount) // strategies.length = validCount
        }
        assembly ("memory-safe") {
            mstore(mload(add(validatedData, 0x20)), validCount) // ppss.length = validCount
        }
        assembly ("memory-safe") {
            mstore(mload(add(validatedData, 0x40)), validCount) // timestamps.length = validCount
        }
        assembly ("memory-safe") {
            mstore(mload(add(validatedData, 0x60)), validCount) // validatorSets.length = validCount
        }
    }

    /// @notice Processes an individual strategy in the batch
    /// @param args Batch update arguments
    /// @param index Index of the strategy to process
    /// @param requiredQuorum Required quorum for validation
    /// @return isValid True if the strategy was processed successfully
    function _processIndividualStrategy(
        UpdatePPSArgs calldata args,
        uint256 index,
        uint256 requiredQuorum
    )
        internal
        returns (bool isValid)
    {
        address _strategy = args.strategies[index];

        // Use self-call + interface for try/catch (update interface signature accordingly)
        try IECDSAPPSOracle(address(this))
            .validateProofs(
                IECDSAPPSOracle.ValidationParams({
                    strategy: _strategy,
                    proofs: args.proofsArray[index],
                    pps: args.ppss[index],
                    timestamp: args.timestamps[index]
                }),
                requiredQuorum
            ) {
            emit PPSValidated(_strategy, args.ppss[index], args.timestamps[index], msg.sender);
        } catch Error(string memory reason) {
            emit ProofValidationFailed(_strategy, reason);
            return false;
        } catch (bytes memory lowLevelData) {
            emit ProofValidationFailedLowLevel(_strategy, lowLevelData);
            return false;
        }

        return true;
    }

    /// @notice Forwards valid entries to SuperVaultAggregator
    /// @param validatedData Struct containing validated batch data
    function _forwardValidEntries(ValidatedBatchData memory validatedData) internal {
        uint256 count = validatedData.strategies.length;

        // Only forward if there are valid entries
        if (count > 0) {
            try ISuperVaultAggregator(SUPER_GOVERNOR.getAddress(SUPER_VAULT_AGGREGATOR))
                .forwardPPS(
                    ISuperVaultAggregator.ForwardPPSArgs({
                        strategies: validatedData.strategies,
                        ppss: validatedData.ppss,
                        timestamps: validatedData.timestamps,
                        updateAuthority: msg.sender
                    })
                ) {
                // [Property 2: Nonce-Based Replay Protection]
                // See security_properties.md Property 2 for full specification.
                //
                // CRITICAL DESIGN DECISION: Increment nonce ONLY after successful forwarding (try block succeeds).
                //
                // Nonces increment when forwardPPS() returns normally (no revert), which includes:
                // 1. ✓ Legitimate PPS updates that are accepted and stored
                // 2. ✓ Business logic rejections using 'return' or 'continue' (not 'revert')
                //    Examples: rate limits exceeded, deviation threshold failures, insufficient upkeep
                //
                // Nonces preserved when forwardPPS() reverts (catch blocks), allowing retry:
                // 3. ✗ Contract reverts (system errors)
                // 4. ✗ Out of gas conditions
                // 5. ✗ Network/RPC failures
                for (uint256 i; i < count; ++i) {
                    noncePerStrategy[validatedData.strategies[i]]++;
                }
            } 
                // [Property 3: Limited Retry Capability]
                // When forwardPPS() reverts (catch blocks), nonces remain unchanged.
                // This allows retrying with the same signatures after external failures resolve.
                // Retry possible for: contract reverts, out of gas, network failures.
                // Retry NOT possible for: business logic rejections (return/continue) that don't revert.
                catch Error(string memory reason) {
                emit BatchForwardPPSFailed(reason);
            } catch (bytes memory lowLevelData) {
                emit BatchForwardPPSFailedLowLevel(lowLevelData);
            }
        }
    }
}
