// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.30;

import "@openzeppelin/contracts/access/IAccessControl.sol";

/*//////////////////////////////////////////////////////////////
                                  ENUMS
    //////////////////////////////////////////////////////////////*/
/// @notice Enum representing SuperAsset fee types
enum SuperAssetFeeType {
    SUPER_ASSET_SWAP_FEE
}

/// @title ISuperRegistry
/// @author Superform Labs
/// @notice Interface for the SuperRegistry contract
/// @dev Registry for VaultBank and SuperAsset related configurations
/// @dev Extracted from SuperGovernor to separate out-of-scope functionality
interface ISuperRegistry is IAccessControl {
    /*//////////////////////////////////////////////////////////////
                                  STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Structure containing Merkle root data for a hook
    struct HookMerkleRootData {
        bytes32 currentRoot; // Current active Merkle root for the hook
        bytes32 proposedRoot; // Proposed new Merkle root (zero if no proposal exists)
        uint256 effectiveTime; // Timestamp when the proposed root becomes effective
    }

    /*//////////////////////////////////////////////////////////////
                                  ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @notice Thrown when providing an invalid address (typically zero address)
    error INVALID_ADDRESS();
    /// @notice Thrown when providing an invalid chain ID
    error INVALID_CHAIN_ID();
    /// @notice Thrown when trying to access a contract that is not registered
    error CONTRACT_NOT_FOUND();
    /// @notice Thrown when timelock period has not expired
    error TIMELOCK_NOT_EXPIRED();
    /// @notice Thrown when a hook is not approved but expected to be
    error HOOK_NOT_APPROVED();
    /// @notice Thrown when no proposed Merkle root exists but one is expected
    error NO_PROPOSED_MERKLE_ROOT();
    /// @notice Thrown when proposing a zero Merkle root
    error ZERO_PROPOSED_MERKLE_ROOT();
    /// @notice Thrown when a relayer is not registered
    error RELAYER_NOT_REGISTERED();
    /// @notice Thrown when a relayer is already registered
    error RELAYER_ALREADY_REGISTERED();
    /// @notice Thrown when a token is already whitelisted
    error TOKEN_ALREADY_WHITELISTED();
    /// @notice Thrown when a token is not proposed for whitelisting but expected to be
    error NOT_PROPOSED_INCENTIVE_TOKEN();
    /// @notice Thrown when a token is not whitelisted but expected to be
    error NOT_WHITELISTED_INCENTIVE_TOKEN();

    /*//////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when a prover is set
    /// @param oldProver The address of the old prover
    /// @param newProver The address of the new prover
    event ProverSet(address indexed oldProver, address indexed newProver);

    /// @notice Emitted when a relayer is added
    /// @param relayer The address of the added relayer
    event RelayerAdded(address indexed relayer);

    /// @notice Emitted when a relayer is removed
    /// @param relayer The address of the removed relayer
    event RelayerRemoved(address indexed relayer);

    /// @notice Emitted when a vault bank is added
    /// @param chainId The chain ID of the added vault bank
    /// @param vaultBank The address of the added vault bank
    event VaultBankAddressAdded(uint64 indexed chainId, address indexed vaultBank);

    /// @notice Emitted when the VaultBank hook Merkle root is proposed
    /// @param hook The hook address for which the Merkle root is being proposed
    /// @param newRoot The new Merkle root
    /// @param effectiveTime The timestamp when the new root will be effective
    event VaultBankHookMerkleRootProposed(address indexed hook, bytes32 newRoot, uint256 effectiveTime);

    /// @notice Emitted when the VaultBank hook Merkle root is updated.
    /// @param hook The address of the hook for which the Merkle root was updated.
    /// @param newRoot The new Merkle root.
    event VaultBankHookMerkleRootUpdated(address indexed hook, bytes32 newRoot);

    /// @notice Emitted when incentive tokens are proposed for whitelisting
    /// @param tokens The addresses of the proposed tokens
    /// @param effectiveTime The timestamp when the proposal will be effective
    event WhitelistedIncentiveTokensProposed(address[] tokens, uint256 effectiveTime);

    /// @notice Emitted when whitelisted incentive tokens are added
    /// @param tokens The addresses of the added tokens
    event WhitelistedIncentiveTokensAdded(address[] tokens);

    /// @notice Emitted when whitelisted incentive tokens are removed
    /// @param tokens The addresses of the removed tokens
    event WhitelistedIncentiveTokensRemoved(address[] tokens);

    /// @notice Emitted when an address is set in the registry
    /// @param key The registry key
    /// @param oldValue The previous address value
    /// @param newValue The new address value
    event AddressSet(bytes32 indexed key, address oldValue, address newValue);

    /*//////////////////////////////////////////////////////////////
                        REGISTRY CONSTANTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns the SuperAsset factory registry key
    /// @return The keccak256 hash used as the registry key for SuperAsset factory
    function SUPER_ASSET_FACTORY() external pure returns (bytes32);

    /// @notice Returns the super registry admin role identifier
    /// @return The keccak256 hash of "SUPER_REGISTRY_ADMIN_ROLE"
    function SUPER_REGISTRY_ADMIN_ROLE() external pure returns (bytes32);

    /// @notice Returns the registry admin role identifier
    /// @return The keccak256 hash of "REGISTRY_ADMIN_ROLE"
    function REGISTRY_ADMIN_ROLE() external pure returns (bytes32);

    /*//////////////////////////////////////////////////////////////
                        PERIPHERY CONFIGURATIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Sets the prover address
    /// @param prover The address of the prover
    function setProver(address prover) external;

    /// @notice Sets an address in the registry
    /// @param key The registry key
    /// @param value The address value to set
    function setAddress(bytes32 key, address value) external;

    /// @notice Gets an address from the registry
    /// @param key The registry key
    /// @return The address value
    function getAddress(bytes32 key) external view returns (address);

    /// @notice Sets the superasset manager for a superasset
    /// @param superAsset The superasset address
    /// @param superAssetManager The new superasset manager address
    function setSuperAssetManager(address superAsset, address superAssetManager) external;

    /// @notice Adds an ICC to the whitelist
    /// @param icc The ICC address to add
    function addICCToWhitelist(address icc) external;

    /// @notice Removes an ICC from the whitelist
    /// @param icc The ICC address to remove
    function removeICCFromWhitelist(address icc) external;

    /*//////////////////////////////////////////////////////////////
                          RELAYER MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @notice Adds a relayer to the approved list
    /// @param relayer The address of the relayer to add
    function addRelayer(address relayer) external;

    /// @notice Removes a relayer from the approved list
    /// @param relayer The address of the relayer to remove
    function removeRelayer(address relayer) external;

    /*//////////////////////////////////////////////////////////////
                           VAULT HOOKS MGMT
    //////////////////////////////////////////////////////////////*/
    /// @notice Proposes a new Merkle root for a specific hook's allowed targets.
    /// @param hook The address of the hook to update the Merkle root for.
    /// @param proposedRoot The proposed new Merkle root.
    function proposeVaultBankHookMerkleRoot(address hook, bytes32 proposedRoot) external;

    /// @notice Executes a previously proposed Merkle root update for a specific hook if the effective time has passed.
    /// @param hook The address of the hook to execute the update for.
    function executeVaultBankHookMerkleRootUpdate(address hook) external;

    /*//////////////////////////////////////////////////////////////
                        VAULT BANK MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @notice Adds a vault bank address for a specific chain ID
    /// @param chainId The chain ID to add the vault bank for
    /// @param vaultBank The address of the vault bank to add
    function addVaultBank(uint64 chainId, address vaultBank) external;

    /*//////////////////////////////////////////////////////////////
                        INCENTIVE TOKEN MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @notice Proposes whitelisted incentive tokens
    /// @param tokens The addresses of the tokens to add
    function proposeAddIncentiveTokens(address[] memory tokens) external;

    /// @notice Executes a previously proposed whitelisted incentive token update after timelock has expired
    function executeAddIncentiveTokens() external;

    /// @notice Proposes a new whitelisted incentive token
    /// @param tokens The addresses of the tokens to add
    function proposeRemoveIncentiveTokens(address[] memory tokens) external;

    /// @notice Executes a previously proposed whitelisted incentive tokens removal after timelock has expired
    function executeRemoveIncentiveTokens() external;

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Gets the vault bank address for a specific chain ID
    /// @param chainId The chain ID to get the vault bank for
    /// @return The vault bank address
    function getVaultBank(uint64 chainId) external view returns (address);

    /// @notice Checks if an address is an approved relayer
    /// @param relayer The address to check
    /// @return True if the address is an approved relayer, false otherwise
    function isRelayer(address relayer) external view returns (bool);

    /// @notice Returns all registered relayers
    /// @return List of relayer addresses
    function getRelayers() external view returns (address[] memory);

    /// @notice Returns the current Merkle root for a specific hook's allowed targets.
    /// @param hook The address of the hook to get the Merkle root for.
    /// @return The Merkle root for the hook's allowed targets.
    function getVaultBankHookMerkleRoot(address hook) external view returns (bytes32);

    /// @notice Gets the proposed Merkle root and its effective time for a specific hook.
    /// @param hook The address of the hook to get the proposed Merkle root for.
    /// @return proposedRoot The proposed Merkle root.
    /// @return effectiveTime The timestamp when the proposed root will become effective.
    function getProposedVaultBankHookMerkleRoot(address hook)
        external
        view
        returns (bytes32 proposedRoot, uint256 effectiveTime);

    /// @notice Checks if a token is whitelisted as an incentive token
    /// @param token The address of the token to check
    /// @return True if the token is whitelisted as an incentive token, false otherwise
    function isWhitelistedIncentiveToken(address token) external view returns (bool);

    /// @notice Gets the prover address
    /// @return The address of the prover
    function getProver() external view returns (address);
}
