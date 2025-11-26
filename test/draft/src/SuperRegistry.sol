// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.30;

// external
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Superform
import { ISuperRegistry, SuperAssetFeeType } from "./interfaces/ISuperRegistry.sol";
import { ISuperAssetFactory } from "./interfaces/SuperAsset/ISuperAssetFactory.sol";

/// @title SuperRegistry
/// @author Superform Labs
/// @notice Registry for VaultBank and SuperAsset related configurations
/// @dev Standalone registry for out-of-scope functionality
contract SuperRegistry is ISuperRegistry, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/
    // Hook registry
    EnumerableSet.AddressSet private _registeredHooks;

    // Relayer registry
    EnumerableSet.AddressSet private _relayers;

    // VaultBank registry
    EnumerableSet.AddressSet private _vaultBanks;
    mapping(uint64 chainId => address vaultBank) private _vaultBanksByChainId;

    // VaultBank Hook Target validation
    mapping(address hook => ISuperRegistry.HookMerkleRootData merkleData) private vaultBankHooksMerkleRoots;

    // Polymer prover
    address private _prover;

    // Whitelisted incentive tokens
    mapping(address token => bool isWhitelisted) private _isWhitelistedIncentiveToken;
    EnumerableSet.AddressSet private _proposedWhitelistedIncentiveTokens;
    EnumerableSet.AddressSet private _proposedRemoveWhitelistedIncentiveTokens;
    uint256 private _proposedAddWhitelistedIncentiveTokensEffectiveTime;
    uint256 private _proposedRemoveWhitelistedIncentiveTokensEffectiveTime;

    // Address registry for draft-specific contracts
    mapping(bytes32 => address) private _addressRegistry;

    // Timelock configuration
    uint256 private constant TIMELOCK = 7 days;

    // Role definitions
    bytes32 private constant _SUPER_REGISTRY_ADMIN_ROLE = keccak256("SUPER_REGISTRY_ADMIN_ROLE");
    bytes32 private constant _REGISTRY_ADMIN_ROLE = keccak256("REGISTRY_ADMIN_ROLE");

    // SuperAsset and VaultBank constants
    bytes32 private constant _SUPER_ASSET_FACTORY = keccak256("SUPER_ASSET_FACTORY");
    bytes32 public constant VAULT_BANK = keccak256("VAULT_BANK");
    uint256 public constant SUPER_ASSET_SWAP_FEE = 4000; // 40% swap fee

    // Fee storage
    mapping(SuperAssetFeeType => uint256) private _feeValues;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @notice Initializes the SuperRegistry contract
    /// @param superRegistryAdmin Address that will have super registry admin role
    /// @param registryAdmin Address that will have registry admin role
    /// @param prover_ Address of the Polymer prover
    constructor(address superRegistryAdmin, address registryAdmin, address prover_) {
        if (superRegistryAdmin == address(0) || registryAdmin == address(0) || prover_ == address(0)) {
            revert INVALID_ADDRESS();
        }

        // Setup roles
        _grantRole(DEFAULT_ADMIN_ROLE, superRegistryAdmin);
        _grantRole(_SUPER_REGISTRY_ADMIN_ROLE, superRegistryAdmin);
        _grantRole(_REGISTRY_ADMIN_ROLE, registryAdmin);

        // Initialize prover
        _prover = prover_;
        emit ProverSet(address(0), prover_);

        // Initialize SuperAsset swap fee
        _feeValues[SuperAssetFeeType.SUPER_ASSET_SWAP_FEE] = SUPER_ASSET_SWAP_FEE; // 40% swap fee
    }

    /*//////////////////////////////////////////////////////////////
                        PERIPHERY CONFIGURATIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperRegistry
    function setProver(address prover) external onlyRole(_SUPER_REGISTRY_ADMIN_ROLE) {
        if (prover == address(0)) revert INVALID_ADDRESS();

        address oldProver = _prover;
        _prover = prover;
        emit ProverSet(oldProver, prover);
    }

    /// @inheritdoc ISuperRegistry
    function setAddress(bytes32 key, address value) external onlyRole(_SUPER_REGISTRY_ADMIN_ROLE) {
        if (value == address(0)) revert INVALID_ADDRESS();

        address oldValue = _addressRegistry[key];
        _addressRegistry[key] = value;
        emit AddressSet(key, oldValue, value);
    }

    /// @inheritdoc ISuperRegistry
    function getAddress(bytes32 key) external view returns (address) {
        address value = _addressRegistry[key];
        if (value == address(0)) revert CONTRACT_NOT_FOUND();
        return value;
    }

    /// @inheritdoc ISuperRegistry
    function setSuperAssetManager(
        address superAsset,
        address superAssetManager
    )
        external
        onlyRole(_REGISTRY_ADMIN_ROLE)
    {
        if (superAsset == address(0) || superAssetManager == address(0)) revert INVALID_ADDRESS();

        address factoryAddress = _addressRegistry[_SUPER_ASSET_FACTORY];
        if (factoryAddress == address(0)) revert CONTRACT_NOT_FOUND();

        ISuperAssetFactory factory = ISuperAssetFactory(factoryAddress);
        factory.setSuperAssetManager(superAsset, superAssetManager);
    }

    /// @inheritdoc ISuperRegistry
    function addICCToWhitelist(address icc) external onlyRole(_SUPER_REGISTRY_ADMIN_ROLE) {
        if (icc == address(0)) revert INVALID_ADDRESS();

        address factoryAddress = _addressRegistry[_SUPER_ASSET_FACTORY];
        if (factoryAddress == address(0)) revert CONTRACT_NOT_FOUND();

        ISuperAssetFactory factory = ISuperAssetFactory(factoryAddress);
        factory.addICCToWhitelist(icc);
    }

    /// @inheritdoc ISuperRegistry
    function removeICCFromWhitelist(address icc) external onlyRole(_SUPER_REGISTRY_ADMIN_ROLE) {
        if (icc == address(0)) revert INVALID_ADDRESS();

        address factoryAddress = _addressRegistry[_SUPER_ASSET_FACTORY];
        if (factoryAddress == address(0)) revert CONTRACT_NOT_FOUND();

        ISuperAssetFactory factory = ISuperAssetFactory(factoryAddress);
        factory.removeICCFromWhitelist(icc);
    }

    /*//////////////////////////////////////////////////////////////
                          HOOK MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @notice Registers a hook
    /// @param hook The address of the hook to register
    function registerHook(address hook) external onlyRole(_REGISTRY_ADMIN_ROLE) {
        if (hook == address(0)) revert INVALID_ADDRESS();
        _registeredHooks.add(hook);
    }

    /// @notice Unregisters a hook
    /// @param hook The address of the hook to unregister
    function unregisterHook(address hook) external onlyRole(_REGISTRY_ADMIN_ROLE) {
        _registeredHooks.remove(hook);
        delete vaultBankHooksMerkleRoots[hook];
    }

    /// @notice Checks if a hook is registered
    /// @param hook The address to check
    /// @return True if hook is registered
    function isHookRegistered(address hook) external view returns (bool) {
        return _registeredHooks.contains(hook);
    }

    /*//////////////////////////////////////////////////////////////
                          RELAYER MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperRegistry
    function addRelayer(address relayer) external onlyRole(_REGISTRY_ADMIN_ROLE) {
        if (relayer == address(0)) revert INVALID_ADDRESS();
        if (!_relayers.add(relayer)) revert RELAYER_ALREADY_REGISTERED();

        emit RelayerAdded(relayer);
    }

    /// @inheritdoc ISuperRegistry
    function removeRelayer(address relayer) external onlyRole(_REGISTRY_ADMIN_ROLE) {
        if (!_relayers.remove(relayer)) revert RELAYER_NOT_REGISTERED();

        emit RelayerRemoved(relayer);
    }

    /*//////////////////////////////////////////////////////////////
                           VAULT HOOKS MGMT
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperRegistry
    function proposeVaultBankHookMerkleRoot(
        address hook,
        bytes32 proposedRoot
    )
        external
        onlyRole(_REGISTRY_ADMIN_ROLE)
    {
        if (!_registeredHooks.contains(hook)) revert HOOK_NOT_APPROVED();
        if (proposedRoot == bytes32(0)) revert ZERO_PROPOSED_MERKLE_ROOT();

        uint256 effectiveTime = block.timestamp + TIMELOCK;
        ISuperRegistry.HookMerkleRootData storage data = vaultBankHooksMerkleRoots[hook];
        data.proposedRoot = proposedRoot;
        data.effectiveTime = effectiveTime;

        emit VaultBankHookMerkleRootProposed(hook, proposedRoot, effectiveTime);
    }

    /// @inheritdoc ISuperRegistry
    function executeVaultBankHookMerkleRootUpdate(address hook) external {
        if (!_registeredHooks.contains(hook)) revert HOOK_NOT_APPROVED();

        ISuperRegistry.HookMerkleRootData storage data = vaultBankHooksMerkleRoots[hook];

        bytes32 proposedRoot = data.proposedRoot;
        if (proposedRoot == bytes32(0)) revert NO_PROPOSED_MERKLE_ROOT();

        if (block.timestamp < data.effectiveTime) revert TIMELOCK_NOT_EXPIRED();

        data.currentRoot = proposedRoot;
        data.proposedRoot = bytes32(0);
        data.effectiveTime = 0;

        emit VaultBankHookMerkleRootUpdated(hook, proposedRoot);
    }

    /*//////////////////////////////////////////////////////////////
                        VAULT BANK MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperRegistry
    function addVaultBank(uint64 chainId, address vaultBank) external onlyRole(_REGISTRY_ADMIN_ROLE) {
        if (chainId == 0) revert INVALID_CHAIN_ID();
        if (vaultBank == address(0)) revert INVALID_ADDRESS();

        if (_vaultBanksByChainId[chainId] != address(0)) {
            _vaultBanks.remove(_vaultBanksByChainId[chainId]);
        }

        _vaultBanks.add(vaultBank);
        _vaultBanksByChainId[chainId] = vaultBank;

        emit VaultBankAddressAdded(chainId, vaultBank);
    }

    /*//////////////////////////////////////////////////////////////
                      INCENTIVE TOKEN MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperRegistry
    function proposeAddIncentiveTokens(address[] memory tokens) external onlyRole(_REGISTRY_ADMIN_ROLE) {
        for (uint256 i; i < tokens.length; i++) {
            if (tokens[i] == address(0)) revert INVALID_ADDRESS();
            _proposedWhitelistedIncentiveTokens.add(tokens[i]);
        }

        _proposedAddWhitelistedIncentiveTokensEffectiveTime = block.timestamp + TIMELOCK;

        emit WhitelistedIncentiveTokensProposed(
            _proposedWhitelistedIncentiveTokens.values(), _proposedAddWhitelistedIncentiveTokensEffectiveTime
        );
    }

    /// @inheritdoc ISuperRegistry
    function executeAddIncentiveTokens() external {
        if (
            _proposedAddWhitelistedIncentiveTokensEffectiveTime == 0
                || block.timestamp < _proposedAddWhitelistedIncentiveTokensEffectiveTime
        ) revert TIMELOCK_NOT_EXPIRED();

        address[] memory tokensToAdd = _proposedWhitelistedIncentiveTokens.values();
        uint256 len = tokensToAdd.length;
        address token;
        for (uint256 i; i < len; i++) {
            token = tokensToAdd[i];
            _isWhitelistedIncentiveToken[token] = true;
            _proposedWhitelistedIncentiveTokens.remove(token);
        }

        emit WhitelistedIncentiveTokensAdded(tokensToAdd);
        _proposedAddWhitelistedIncentiveTokensEffectiveTime = 0;
    }

    /// @inheritdoc ISuperRegistry
    function proposeRemoveIncentiveTokens(address[] memory tokens) external onlyRole(_REGISTRY_ADMIN_ROLE) {
        for (uint256 i; i < tokens.length; i++) {
            if (tokens[i] == address(0)) revert INVALID_ADDRESS();
            if (!_isWhitelistedIncentiveToken[tokens[i]]) revert NOT_WHITELISTED_INCENTIVE_TOKEN();

            _proposedRemoveWhitelistedIncentiveTokens.add(tokens[i]);
        }

        _proposedRemoveWhitelistedIncentiveTokensEffectiveTime = block.timestamp + TIMELOCK;

        emit WhitelistedIncentiveTokensProposed(
            _proposedRemoveWhitelistedIncentiveTokens.values(), _proposedRemoveWhitelistedIncentiveTokensEffectiveTime
        );
    }

    /// @inheritdoc ISuperRegistry
    function executeRemoveIncentiveTokens() external {
        if (
            _proposedRemoveWhitelistedIncentiveTokensEffectiveTime == 0
                || block.timestamp < _proposedRemoveWhitelistedIncentiveTokensEffectiveTime
        ) revert TIMELOCK_NOT_EXPIRED();

        address[] memory tokensToRemove = _proposedRemoveWhitelistedIncentiveTokens.values();
        uint256 len = tokensToRemove.length;
        address token;
        for (uint256 i; i < len; i++) {
            token = tokensToRemove[i];
            if (_isWhitelistedIncentiveToken[token]) {
                _isWhitelistedIncentiveToken[token] = false;
            }
            _proposedRemoveWhitelistedIncentiveTokens.remove(token);
        }

        emit WhitelistedIncentiveTokensRemoved(tokensToRemove);
        _proposedRemoveWhitelistedIncentiveTokensEffectiveTime = 0;
    }

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperRegistry
    function getVaultBank(uint64 chainId) external view returns (address) {
        return _vaultBanksByChainId[chainId];
    }

    /// @inheritdoc ISuperRegistry
    function isRelayer(address relayer) external view returns (bool) {
        return _relayers.contains(relayer);
    }

    /// @inheritdoc ISuperRegistry
    function getRelayers() external view returns (address[] memory) {
        return _relayers.values();
    }

    /// @inheritdoc ISuperRegistry
    function getVaultBankHookMerkleRoot(address hook) external view returns (bytes32) {
        if (!_registeredHooks.contains(hook)) revert HOOK_NOT_APPROVED();
        return vaultBankHooksMerkleRoots[hook].currentRoot;
    }

    /// @inheritdoc ISuperRegistry
    function getProposedVaultBankHookMerkleRoot(address hook)
        external
        view
        returns (bytes32 proposedRoot, uint256 effectiveTime)
    {
        if (!_registeredHooks.contains(hook)) revert HOOK_NOT_APPROVED();
        ISuperRegistry.HookMerkleRootData storage data = vaultBankHooksMerkleRoots[hook];
        return (data.proposedRoot, data.effectiveTime);
    }

    /// @inheritdoc ISuperRegistry
    function isWhitelistedIncentiveToken(address token) external view returns (bool) {
        return _isWhitelistedIncentiveToken[token];
    }

    /// @inheritdoc ISuperRegistry
    function getProver() external view returns (address) {
        return _prover;
    }

    /*//////////////////////////////////////////////////////////////
                        REGISTRY CONSTANTS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperRegistry
    function SUPER_ASSET_FACTORY() external pure returns (bytes32) {
        return _SUPER_ASSET_FACTORY;
    }

    /// @inheritdoc ISuperRegistry
    function SUPER_REGISTRY_ADMIN_ROLE() external pure returns (bytes32) {
        return _SUPER_REGISTRY_ADMIN_ROLE;
    }

    /// @inheritdoc ISuperRegistry
    function REGISTRY_ADMIN_ROLE() external pure returns (bytes32) {
        return _REGISTRY_ADMIN_ROLE;
    }

    /// @dev Advertise ISuperRegistry support for ERC-165 detection
    function supportsInterface(bytes4 interfaceId) public view override(AccessControl) returns (bool) {
        return interfaceId == type(ISuperRegistry).interfaceId || super.supportsInterface(interfaceId);
    }
}
