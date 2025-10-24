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
    bytes32 public constant UPDATE_PPS_TYPEHASH =
        keccak256("UpdatePPS(address strategy,uint256 pps,uint256 ppsStdev,uint256 timestamp,uint256 strategyNonce)");

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
    function updatePPS(UpdatePPSArgs memory args) external {
        uint256 strategiesLength = args.strategies.length;

        if (strategiesLength == 0) revert ZERO_LENGTH_ARRAY();
        // Validate input array lengths
        if (
            strategiesLength != args.proofsArray.length || strategiesLength != args.ppss.length
                || strategiesLength != args.ppsStdevs.length || strategiesLength != args.timestamps.length
        ) revert ARRAY_LENGTH_MISMATCH();

        (UpdatePPSArgs memory processedArgs, uint256[] memory validatorSets, uint256 validCount) = _processBatchStrategies(args, strategiesLength);
        _forwardValidEntries(processedArgs, validatorSets, validCount);
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
    function validateProofs(
        IECDSAPPSOracle.ValidationParams memory params,
        uint256 requiredQuorum
    )
        public
        view
    {
        _validateProofs(params, requiredQuorum);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Validates an array of proofs for a strategy's PPS update
    /// @dev Check for this being the active PPS Oracle already done by SuperVaultAggregator
    /// @param params Validation parameters
    /// @param requiredQuorum Required quorum for validation
    /// @dev Reverts immediately if duplicate signers are found or quorum is not met
    function _validateProofs(
        IECDSAPPSOracle.ValidationParams memory params,
        uint256 requiredQuorum
    )
        internal
        view
    {
        ProofValidationVars memory vars;
        vars.proofsLength = params.proofs.length;

        if (vars.proofsLength == 0) revert ZERO_LENGTH_ARRAY();

        // Quorum from batch-snapshot
        if (vars.proofsLength < requiredQuorum) revert QUORUM_NOT_MET();

        // Build EIP-712 digest
        vars.digest = _hashTypedDataV4(
            keccak256(
                abi.encodePacked(
                    UPDATE_PPS_TYPEHASH,
                    params.strategy,
                    params.pps,
                    params.ppsStdev,
                    params.timestamp,
                    noncePerStrategy[params.strategy]
                )
            )
        );

        // Process each proof
        for (uint256 i; i < vars.proofsLength; i++) {
            // Recover the signer from the proof
            vars.signer = ECDSA.recover(vars.digest, params.proofs[i]);

            // Verify the signer is a registered validator
            if (!SUPER_GOVERNOR.isValidator(vars.signer)) revert INVALID_VALIDATOR();

            // Check for duplicates or improper ordering - signers must be in ascending order
            if (vars.signer <= vars.lastSigner) revert INVALID_PROOF();
            vars.lastSigner = vars.signer;
        }
    }

    /// @notice Processes batch strategies and returns valid entries
    /// @param args Batch update arguments
    /// @param strategiesLength Length of strategies array
    /// @return validatedData Struct containing all validated batch data
    function _processBatchStrategies(
        UpdatePPSArgs memory args,
        uint256 strategiesLength
    )
        internal
        returns (UpdatePPSArgs memory, uint256[] memory, uint256)
    {
        uint256 requiredQuorum = SUPER_GOVERNOR.getPPSOracleQuorum();

        uint256[] memory validatorSets = new uint256[](strategiesLength);

        uint256 validCount;

        for (uint256 i; i < strategiesLength; ++i) {
            bool isValid = _processIndividualStrategy(args, i, requiredQuorum);

            validatorSets[i] = args.proofsArray[i].length;

            if (!isValid) {
                // Invalidate the entry by setting strategy to address(0)
                args.strategies[i] = address(0);
            } else {
                unchecked {
                    ++validCount;
                }
            }
        }
        return (args, validatorSets, validCount);
    }

    /// @notice Processes an individual strategy in the batch
    /// @param args Batch update arguments
    /// @param index Index of the strategy to process
    /// @param requiredQuorum Required quorum for validation
    /// @return isValid True if the strategy was processed successfully
    function _processIndividualStrategy(
        UpdatePPSArgs memory args,
        uint256 index,
        uint256 requiredQuorum
    )
        internal
        returns (bool isValid)
    {
        address _strategy = args.strategies[index];

        try IECDSAPPSOracle(address(this))
            .validateProofs(
                IECDSAPPSOracle.ValidationParams({
                    strategy: _strategy,
                    proofs: args.proofsArray[index],
                    pps: args.ppss[index],
                    ppsStdev: args.ppsStdevs[index],
                    timestamp: args.timestamps[index]
                }),
                requiredQuorum
            ) {
            emit PPSValidated(_strategy, args.ppss[index], args.ppsStdevs[index], args.timestamps[index], msg.sender);
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
    /// @param args Struct containing batch data
    /// @param validatorSets Array of validator sets for each strategy
    /// @param validCount Number of valid entries
    function _forwardValidEntries(
        UpdatePPSArgs memory args,
        uint256[] memory validatorSets,
        uint256 validCount
    )
        internal
    {
        uint256 totalGas = validCount * SUPER_GOVERNOR.getGasInfo(address(this));
        uint256 gasBefore = gasleft();
        if (gasBefore <= totalGas + gasBefore / 64) {
            emit InsufficientGasForForward(gasBefore, totalGas);
            return;
        }
        gasBefore = gasleft();
        // Only forward if there are valid entries
        if (validCount > 0) {
            try ISuperVaultAggregator(SUPER_GOVERNOR.getAddress(SUPER_VAULT_AGGREGATOR))
                .forwardPPS(
                    ISuperVaultAggregator.ForwardPPSArgs({
                        strategies: args.strategies,
                        ppss: args.ppss,
                        ppsStdevs: args.ppsStdevs,
                        validatorSets: validatorSets,
                        timestamps: args.timestamps,
                        updateAuthority: msg.sender
                    })
                ) { }
            catch Error(string memory reason) {
                // Require that enough gas was provided to prevent an OOG revert
                if (gasleft() <= gasBefore / 64) revert INSUFFICIENT_GAS_FOR_EXTERNAL_CALL();

                emit BatchForwardPPSFailed(reason);
            } catch (bytes memory lowLevelData) {
                // Require that enough gas was provided to prevent an OOG revert
                if (gasleft() <= gasBefore / 64) revert INSUFFICIENT_GAS_FOR_EXTERNAL_CALL();

                emit BatchForwardPPSFailedLowLevel(lowLevelData);
            }
        }
    }
}
