// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract MockSuperGovernor {
    //<>=============================================================<>
    //||                                                             ||
    //||                    NON-VIEW FUNCTIONS                       ||
    //||                                                             ||
    //<>=============================================================<>
    // Mock implementation of addExecutor
    function addExecutor(address executor) public {}

    // Mock implementation of addICCToWhitelist
    function addICCToWhitelist(address icc) public {}

    // Mock implementation of addRelayer
    function addRelayer(address relayer) public {}

    // Mock implementation of addSuperformManager
    function addSuperformManager(address manager) public {}

    // Mock implementation of addValidator
    function addValidator(address validator) public {}

    // Mock implementation of addVaultBank
    function addVaultBank(uint64 chainId, address vaultBank) public {}

    // Mock implementation of batchSetEmergencyPrices
    function batchSetEmergencyPrices(
        address[] memory tokens_,
        uint256[] memory prices_
    ) public {}

    // Mock implementation of batchSetOracleUptimeFeed
    function batchSetOracleUptimeFeed(
        address[] memory dataOracles_,
        address[] memory uptimeOracles_,
        uint256[] memory gracePeriods_
    ) public {}

    // Mock implementation of changeHooksRootUpdateTimelock
    function changeHooksRootUpdateTimelock(uint256 newTimelock) public {}

    // Mock implementation of changePrimaryManager
    function changePrimaryManager(
        address strategy,
        address newManager
    ) public {}

    // Mock implementation of executeActivePPSOracleChange
    function executeActivePPSOracleChange() public {}

    // Mock implementation of executeAddIncentiveTokens
    function executeAddIncentiveTokens() public {}

    // Mock implementation of executeFeeUpdate
    function executeFeeUpdate(uint8 feeType) public {}

    // Mock implementation of executeMinStalenesChange
    function executeMinStalenesChange() public {}

    // Mock implementation of executeRemoveIncentiveTokens
    function executeRemoveIncentiveTokens() public {}

    // Mock implementation of executeSuperBankHookMerkleRootUpdate
    function executeSuperBankHookMerkleRootUpdate(address hook) public {}

    // Mock implementation of executeUpkeepClaim
    function executeUpkeepClaim(uint256 amount) public {}

    // Mock implementation of executeUpkeepPaymentsChange
    function executeUpkeepPaymentsChange() public {}

    // Mock implementation of executeVaultBankHookMerkleRootUpdate
    function executeVaultBankHookMerkleRootUpdate(address hook) public {}

    // Mock implementation of freezeManagerTakeover
    function freezeManagerTakeover() public {}

    // Mock implementation of grantRole
    function grantRole(bytes32 role, address account) public {}

    // Mock implementation of proposeActivePPSOracle
    function proposeActivePPSOracle(address oracle) public {}

    // Mock implementation of proposeAddIncentiveTokens
    function proposeAddIncentiveTokens(address[] memory tokens) public {}

    // Mock implementation of proposeFee
    function proposeFee(uint8 feeType, uint256 value) public {}

    // Mock implementation of proposeGlobalHooksRoot
    function proposeGlobalHooksRoot(bytes32 newRoot) public {}

    // Mock implementation of proposeMinStaleness
    function proposeMinStaleness(uint256 newMinStaleness) public {}

    // Mock implementation of proposeRemoveIncentiveTokens
    function proposeRemoveIncentiveTokens(address[] memory tokens) public {}

    // Mock implementation of proposeSuperBankHookMerkleRoot
    function proposeSuperBankHookMerkleRoot(
        address hook,
        bytes32 proposedRoot
    ) public {}

    // Mock implementation of proposeUpkeepPaymentsChange
    function proposeUpkeepPaymentsChange(bool enabled) public {}

    // Mock implementation of proposeVaultBankHookMerkleRoot
    function proposeVaultBankHookMerkleRoot(
        address hook,
        bytes32 proposedRoot
    ) public {}

    // Mock implementation of queueOracleProviderRemoval
    function queueOracleProviderRemoval(bytes32[] memory providers) public {}

    // Mock implementation of queueOracleUpdate
    function queueOracleUpdate(
        address[] memory bases_,
        address[] memory quotes_,
        bytes32[] memory providers_,
        address[] memory feeds_
    ) public {}

    // Mock implementation of registerHook
    function registerHook(address hook, bool isFulfillRequestsHook) public {}

    // Mock implementation of registerProtectedKeeper
    function registerProtectedKeeper(address keeper) public {}

    // Mock implementation of removeExecutor
    function removeExecutor(address executor) public {}

    // Mock implementation of removeICCFromWhitelist
    function removeICCFromWhitelist(address icc) public {}

    // Mock implementation of removeRelayer
    function removeRelayer(address relayer) public {}

    // Mock implementation of removeSuperformManager
    function removeSuperformManager(address manager) public {}

    // Mock implementation of removeValidator
    function removeValidator(address validator) public {}

    // Mock implementation of renounceRole
    function renounceRole(bytes32 role, address callerConfirmation) public {}

    // Mock implementation of revokeRole
    function revokeRole(bytes32 role, address account) public {}

    // Mock implementation of setActivePPSOracle
    function setActivePPSOracle(address oracle) public {}

    // Mock implementation of setAddress
    function setAddress(bytes32 key, address value) public {}

    // Mock implementation of setEmergencyPrice
    function setEmergencyPrice(address token, uint256 price) public {}

    // Mock implementation of setGasInfo
    function setGasInfo(
        address oracle,
        uint256 baseGasBatch,
        uint256 gasIncreasePerEntryBatch
    ) public {}

    // Mock implementation of setGlobalHooksRootVetoStatus
    function setGlobalHooksRootVetoStatus(bool vetoed) public {}

    // Mock implementation of setOracleFeedMaxStaleness
    function setOracleFeedMaxStaleness(
        address feed,
        uint256 newMaxStaleness
    ) public {}

    // Mock implementation of setOracleFeedMaxStalenessBatch
    function setOracleFeedMaxStalenessBatch(
        address[] memory feeds_,
        uint256[] memory newMaxStalenessList_
    ) public {}

    // Mock implementation of setOracleMaxStaleness
    function setOracleMaxStaleness(uint256 newMaxStaleness) public {}

    // Mock implementation of setPPSOracleQuorum
    function setPPSOracleQuorum(uint256 quorum) public {}

    // Mock implementation of setProver
    function setProver(address prover) public {}

    // Mock implementation of setStrategyHooksRootVetoStatus
    function setStrategyHooksRootVetoStatus(
        address strategy,
        bool vetoed
    ) public {}

    // Mock implementation of setSuperAssetManager
    function setSuperAssetManager(
        address superAsset,
        address superAssetManager
    ) public {}

    // Mock implementation of unregisterHook
    function unregisterHook(address hook) public {}

    // Mock implementation of unregisterProtectedKeeper
    function unregisterProtectedKeeper(address keeper) public {}

    //<>=============================================================<>
    //||                                                             ||
    //||                    SETTER FUNCTIONS                         ||
    //||                                                             ||
    //<>=============================================================<>
    // Function to set return values for BANK_MANAGER
    function setBANK_MANAGERReturn(bytes32 _value0) public {
        _BANK_MANAGERReturn_0 = _value0;
    }

    // Function to set return values for BANK_MANAGER_ROLE
    function setBANK_MANAGER_ROLEReturn(bytes32 _value0) public {
        _BANK_MANAGER_ROLEReturn_0 = _value0;
    }

    // Function to set return values for DEFAULT_ADMIN_ROLE
    function setDEFAULT_ADMIN_ROLEReturn(bytes32 _value0) public {
        _DEFAULT_ADMIN_ROLEReturn_0 = _value0;
    }

    // Function to set return values for ECDSAPPSORACLE
    function setECDSAPPSORACLEReturn(bytes32 _value0) public {
        _ECDSAPPSORACLEReturn_0 = _value0;
    }

    // Function to set return values for GAS_MANAGER_ROLE
    function setGAS_MANAGER_ROLEReturn(bytes32 _value0) public {
        _GAS_MANAGER_ROLEReturn_0 = _value0;
    }

    // Function to set return values for GOVERNOR_ROLE
    function setGOVERNOR_ROLEReturn(bytes32 _value0) public {
        _GOVERNOR_ROLEReturn_0 = _value0;
    }

    // Function to set return values for GUARDIAN_ROLE
    function setGUARDIAN_ROLEReturn(bytes32 _value0) public {
        _GUARDIAN_ROLEReturn_0 = _value0;
    }

    // Function to set return values for SUP
    function setSUPReturn(bytes32 _value0) public {
        _SUPReturn_0 = _value0;
    }

    // Function to set return values for SUPER_ASSET_FACTORY
    function setSUPER_ASSET_FACTORYReturn(bytes32 _value0) public {
        _SUPER_ASSET_FACTORYReturn_0 = _value0;
    }

    // Function to set return values for SUPER_BANK
    function setSUPER_BANKReturn(bytes32 _value0) public {
        _SUPER_BANKReturn_0 = _value0;
    }

    // Function to set return values for SUPER_GOVERNOR_ROLE
    function setSUPER_GOVERNOR_ROLEReturn(bytes32 _value0) public {
        _SUPER_GOVERNOR_ROLEReturn_0 = _value0;
    }

    // Function to set return values for SUPER_ORACLE
    function setSUPER_ORACLEReturn(bytes32 _value0) public {
        _SUPER_ORACLEReturn_0 = _value0;
    }

    // Function to set return values for SUPER_VAULT_AGGREGATOR
    function setSUPER_VAULT_AGGREGATORReturn(bytes32 _value0) public {
        _SUPER_VAULT_AGGREGATORReturn_0 = _value0;
    }

    // Function to set return values for TREASURY
    function setTREASURYReturn(bytes32 _value0) public {
        _TREASURYReturn_0 = _value0;
    }

    // Function to set return values for UP
    function setUPReturn(bytes32 _value0) public {
        _UPReturn_0 = _value0;
    }

    // Function to set return values for VAULT_BANK
    function setVAULT_BANKReturn(bytes32 _value0) public {
        _VAULT_BANKReturn_0 = _value0;
    }

    // Function to set return values for getActivePPSOracle
    function setGetActivePPSOracleReturn(address _value0) public {
        _getActivePPSOracleReturn_0 = _value0;
    }

    // Function to set return values for getAddress
    function setGetAddressReturn(address _value0) public {
        _getAddressReturn_0 = _value0;
    }

    // Function to set return values for getAllSuperformManagers
    function setGetAllSuperformManagersReturn(address[] memory _value0) public {
        delete _getAllSuperformManagersReturn_0;
        for (uint i = 0; i < _value0.length; i++) {
            _getAllSuperformManagersReturn_0.push(_value0[i]);
        }
    }

    // Function to set return values for getExecutors
    function setGetExecutorsReturn(address[] memory _value0) public {
        delete _getExecutorsReturn_0;
        for (uint i = 0; i < _value0.length; i++) {
            _getExecutorsReturn_0.push(_value0[i]);
        }
    }

    // Function to set return values for getFee
    function setGetFeeReturn(uint256 _value0) public {
        _getFeeReturn_0 = _value0;
    }

    // Function to set return values for getGasInfo
    function setGetGasInfoReturn(ISuperGovernor_GasInfo memory _value0) public {
        _getGasInfoReturn_0 = _value0;
    }

    // Function to set return values for getManagersPaginated
    function setGetManagersPaginatedReturn(
        address[] memory _value0,
        uint256 _value1
    ) public {
        delete _getManagersPaginatedReturn_0;
        for (uint i = 0; i < _value0.length; i++) {
            _getManagersPaginatedReturn_0.push(_value0[i]);
        }
        _getManagersPaginatedReturn_1 = _value1;
    }

    // Function to set return values for getMinStaleness
    function setGetMinStalenessReturn(uint256 _value0) public {
        _getMinStalenessReturn_0 = _value0;
    }

    // Function to set return values for getPPSOracleQuorum
    function setGetPPSOracleQuorumReturn(uint256 _value0) public {
        _getPPSOracleQuorumReturn_0 = _value0;
    }

    // Function to set return values for getProposedActivePPSOracle
    function setGetProposedActivePPSOracleReturn(
        address _value0,
        uint256 _value1
    ) public {
        _getProposedActivePPSOracleReturn_0 = _value0;
        _getProposedActivePPSOracleReturn_1 = _value1;
    }

    // Function to set return values for getProposedMinStaleness
    function setGetProposedMinStalenessReturn(
        uint256 _value0,
        uint256 _value1
    ) public {
        _getProposedMinStalenessReturn_0 = _value0;
        _getProposedMinStalenessReturn_1 = _value1;
    }

    // Function to set return values for getProposedSuperBankHookMerkleRoot
    function setGetProposedSuperBankHookMerkleRootReturn(
        bytes32 _value0,
        uint256 _value1
    ) public {
        _getProposedSuperBankHookMerkleRootReturn_0 = _value0;
        _getProposedSuperBankHookMerkleRootReturn_1 = _value1;
    }

    // Function to set return values for getProposedUpkeepPaymentsStatus
    function setGetProposedUpkeepPaymentsStatusReturn(
        bool _value0,
        uint256 _value1
    ) public {
        _getProposedUpkeepPaymentsStatusReturn_0 = _value0;
        _getProposedUpkeepPaymentsStatusReturn_1 = _value1;
    }

    // Function to set return values for getProposedVaultBankHookMerkleRoot
    function setGetProposedVaultBankHookMerkleRootReturn(
        bytes32 _value0,
        uint256 _value1
    ) public {
        _getProposedVaultBankHookMerkleRootReturn_0 = _value0;
        _getProposedVaultBankHookMerkleRootReturn_1 = _value1;
    }

    // Function to set return values for getProtectedKeepers
    function setGetProtectedKeepersReturn(address[] memory _value0) public {
        delete _getProtectedKeepersReturn_0;
        for (uint i = 0; i < _value0.length; i++) {
            _getProtectedKeepersReturn_0.push(_value0[i]);
        }
    }

    // Function to set return values for getProtectedKeepersCount
    function setGetProtectedKeepersCountReturn(uint256 _value0) public {
        _getProtectedKeepersCountReturn_0 = _value0;
    }

    // Function to set return values for getProver
    function setGetProverReturn(address _value0) public {
        _getProverReturn_0 = _value0;
    }

    // Function to set return values for getRegisteredFulfillRequestsHooks
    function setGetRegisteredFulfillRequestsHooksReturn(
        address[] memory _value0
    ) public {
        delete _getRegisteredFulfillRequestsHooksReturn_0;
        for (uint i = 0; i < _value0.length; i++) {
            _getRegisteredFulfillRequestsHooksReturn_0.push(_value0[i]);
        }
    }

    // Function to set return values for getRegisteredHooks
    function setGetRegisteredHooksReturn(address[] memory _value0) public {
        delete _getRegisteredHooksReturn_0;
        for (uint i = 0; i < _value0.length; i++) {
            _getRegisteredHooksReturn_0.push(_value0[i]);
        }
    }

    // Function to set return values for getRelayers
    function setGetRelayersReturn(address[] memory _value0) public {
        delete _getRelayersReturn_0;
        for (uint i = 0; i < _value0.length; i++) {
            _getRelayersReturn_0.push(_value0[i]);
        }
    }

    // Function to set return values for getRoleAdmin
    function setGetRoleAdminReturn(bytes32 _value0) public {
        _getRoleAdminReturn_0 = _value0;
    }

    // Function to set return values for getSuperBankHookMerkleRoot
    function setGetSuperBankHookMerkleRootReturn(bytes32 _value0) public {
        _getSuperBankHookMerkleRootReturn_0 = _value0;
    }

    // Function to set return values for getSuperformManagersCount
    function setGetSuperformManagersCountReturn(uint256 _value0) public {
        _getSuperformManagersCountReturn_0 = _value0;
    }

    // Function to set return values for getUpkeepCostPerBatchUpdate
    function setGetUpkeepCostPerBatchUpdateReturn(uint256 _value0) public {
        _getUpkeepCostPerBatchUpdateReturn_0 = _value0;
    }

    // Function to set return values for getValidators
    function setGetValidatorsReturn(address[] memory _value0) public {
        delete _getValidatorsReturn_0;
        for (uint i = 0; i < _value0.length; i++) {
            _getValidatorsReturn_0.push(_value0[i]);
        }
    }

    // Function to set return values for getVaultBank
    function setGetVaultBankReturn(address _value0) public {
        _getVaultBankReturn_0 = _value0;
    }

    // Function to set return values for getVaultBankHookMerkleRoot
    function setGetVaultBankHookMerkleRootReturn(bytes32 _value0) public {
        _getVaultBankHookMerkleRootReturn_0 = _value0;
    }

    // Function to set return values for hasRole
    function setHasRoleReturn(bool _value0) public {
        _hasRoleReturn_0 = _value0;
    }

    // Function to set return values for isActivePPSOracle
    function setIsActivePPSOracleReturn(bool _value0) public {
        _isActivePPSOracleReturn_0 = _value0;
    }

    // Function to set return values for isExecutor
    function setIsExecutorReturn(bool _value0) public {
        _isExecutorReturn_0 = _value0;
    }

    // Function to set return values for isFulfillRequestsHookRegistered
    function setIsFulfillRequestsHookRegisteredReturn(bool _value0) public {
        _isFulfillRequestsHookRegisteredReturn_0 = _value0;
    }

    // Function to set return values for isGuardian
    function setIsGuardianReturn(bool _value0) public {
        _isGuardianReturn_0 = _value0;
    }

    // Function to set return values for isHookRegistered
    function setIsHookRegisteredReturn(bool _value0) public {
        _isHookRegisteredReturn_0 = _value0;
    }

    // Function to set return values for isManagerTakeoverFrozen
    function setIsManagerTakeoverFrozenReturn(bool _value0) public {
        _isManagerTakeoverFrozenReturn_0 = _value0;
    }

    // Function to set return values for isProtectedKeeper
    function setIsProtectedKeeperReturn(bool _value0) public {
        _isProtectedKeeperReturn_0 = _value0;
    }

    // Function to set return values for isRelayer
    function setIsRelayerReturn(bool _value0) public {
        _isRelayerReturn_0 = _value0;
    }

    // Function to set return values for isSuperformManager
    function setIsSuperformManagerReturn(bool _value0) public {
        _isSuperformManagerReturn_0 = _value0;
    }

    // Function to set return values for isUpkeepPaymentsEnabled
    function setIsUpkeepPaymentsEnabledReturn(bool _value0) public {
        _isUpkeepPaymentsEnabledReturn_0 = _value0;
    }

    // Function to set return values for isValidator
    function setIsValidatorReturn(bool _value0) public {
        _isValidatorReturn_0 = _value0;
    }

    // Function to set return values for isWhitelistedIncentiveToken
    function setIsWhitelistedIncentiveTokenReturn(bool _value0) public {
        _isWhitelistedIncentiveTokenReturn_0 = _value0;
    }

    // Function to set return values for supportsInterface
    function setSupportsInterfaceReturn(bool _value0) public {
        _supportsInterfaceReturn_0 = _value0;
    }

    /*******************************************************************
     *   ⚠️ WARNING ⚠️ WARNING ⚠️ WARNING ⚠️ WARNING ⚠️ WARNING ⚠️  *
     *-----------------------------------------------------------------*
     *      Generally you only need to modify the sections above.      *
     *          The code below handles system operations.              *
     *******************************************************************/

    //<>=============================================================<>
    //||                                                             ||
    //||        ⚠️  STRUCT DEFINITIONS - DO NOT MODIFY  ⚠️          ||
    //||                                                             ||
    //<>=============================================================<>
    // Struct definition for ISuperGovernor_GasInfo
    struct ISuperGovernor_GasInfo {
        uint256 baseGasBatch;
        uint256 gasIncreasePerEntryBatch;
    }

    //<>=============================================================<>
    //||                                                             ||
    //||        ⚠️  EVENTS DEFINITIONS - DO NOT MODIFY  ⚠️          ||
    //||                                                             ||
    //<>=============================================================<>
    event ActivePPSOracleChanged(address oldOracle, address newOracle);
    event ActivePPSOracleProposed(address oracle, uint256 effectiveTime);
    event ActivePPSOracleSet(address oracle);
    event AddressSet(bytes32 key, address value);
    event ExecutorAdded(address executor);
    event ExecutorRemoved(address executor);
    event FeeProposed(uint8 feeType, uint256 value, uint256 effectiveTime);
    event FeeUpdated(uint8 feeType, uint256 value);
    event FulfillRequestsHookRegistered(address hook);
    event FulfillRequestsHookUnregistered(address hook);
    event GasInfoSet(
        address oracle,
        uint256 baseGasBatch,
        uint256 gasIncreasePerEntryBatch
    );
    event HookApproved(address hook);
    event HookRemoved(address hook);
    event ManagerTakeoversFrozen();
    event MinStalenesChanged(uint256 newMinStaleness);
    event MinStalenesProposed(uint256 newMinStaleness, uint256 effectiveTime);
    event PPSOracleQuorumUpdated(uint256 quorum);
    event ProtectedKeeperRegistered(address keeper);
    event ProtectedKeeperUnregistered(address keeper);
    event ProverSet(address prover);
    event RelayerAdded(address relayer);
    event RelayerRemoved(address relayer);
    event RevenueShareUpdated(uint256 share);
    event RoleAdminChanged(
        bytes32 role,
        bytes32 previousAdminRole,
        bytes32 newAdminRole
    );
    event RoleGranted(bytes32 role, address account, address sender);
    event RoleRevoked(bytes32 role, address account, address sender);
    event SuperBankHookMerkleRootProposed(
        address hook,
        bytes32 newRoot,
        uint256 effectiveTime
    );
    event SuperBankHookMerkleRootUpdated(address hook, bytes32 newRoot);
    event SuperformManagerAdded(address manager);
    event SuperformManagerRemoved(address manager);
    event UpkeepPaymentsChangeProposed(bool enabled, uint256 effectiveTime);
    event UpkeepPaymentsChanged(bool enabled);
    event ValidatorAdded(address validator);
    event ValidatorRemoved(address validator);
    event VaultBankAddressAdded(uint64 chainId, address vaultBank);
    event VaultBankHookMerkleRootProposed(
        address hook,
        bytes32 newRoot,
        uint256 effectiveTime
    );
    event VaultBankHookMerkleRootUpdated(address hook, bytes32 newRoot);
    event WhitelistedIncentiveTokensAdded(address[] tokens);
    event WhitelistedIncentiveTokensProposed(
        address[] tokens,
        uint256 effectiveTime
    );
    event WhitelistedIncentiveTokensRemoved(address[] tokens);

    //<>=============================================================<>
    //||                                                             ||
    //||         ⚠️  INTERNAL STORAGE - DO NOT MODIFY  ⚠️           ||
    //||                                                             ||
    //<>=============================================================<>
    bytes32 private _BANK_MANAGERReturn_0;
    bytes32 private _BANK_MANAGER_ROLEReturn_0;
    bytes32 private _DEFAULT_ADMIN_ROLEReturn_0;
    bytes32 private _ECDSAPPSORACLEReturn_0;
    bytes32 private _GAS_MANAGER_ROLEReturn_0;
    bytes32 private _GOVERNOR_ROLEReturn_0;
    bytes32 private _GUARDIAN_ROLEReturn_0;
    bytes32 private _SUPReturn_0;
    bytes32 private _SUPER_ASSET_FACTORYReturn_0;
    bytes32 private _SUPER_BANKReturn_0;
    bytes32 private _SUPER_GOVERNOR_ROLEReturn_0;
    bytes32 private _SUPER_ORACLEReturn_0;
    bytes32 private _SUPER_VAULT_AGGREGATORReturn_0;
    bytes32 private _TREASURYReturn_0;
    bytes32 private _UPReturn_0;
    bytes32 private _VAULT_BANKReturn_0;
    address private _getActivePPSOracleReturn_0;
    address private _getAddressReturn_0;
    address[] private _getAllSuperformManagersReturn_0;
    address[] private _getExecutorsReturn_0;
    uint256 private _getFeeReturn_0;
    ISuperGovernor_GasInfo private _getGasInfoReturn_0;
    address[] private _getManagersPaginatedReturn_0;
    uint256 private _getManagersPaginatedReturn_1;
    uint256 private _getMinStalenessReturn_0;
    uint256 private _getPPSOracleQuorumReturn_0;
    address private _getProposedActivePPSOracleReturn_0;
    uint256 private _getProposedActivePPSOracleReturn_1;
    uint256 private _getProposedMinStalenessReturn_0;
    uint256 private _getProposedMinStalenessReturn_1;
    bytes32 private _getProposedSuperBankHookMerkleRootReturn_0;
    uint256 private _getProposedSuperBankHookMerkleRootReturn_1;
    bool private _getProposedUpkeepPaymentsStatusReturn_0;
    uint256 private _getProposedUpkeepPaymentsStatusReturn_1;
    bytes32 private _getProposedVaultBankHookMerkleRootReturn_0;
    uint256 private _getProposedVaultBankHookMerkleRootReturn_1;
    address[] private _getProtectedKeepersReturn_0;
    uint256 private _getProtectedKeepersCountReturn_0;
    address private _getProverReturn_0;
    address[] private _getRegisteredFulfillRequestsHooksReturn_0;
    address[] private _getRegisteredHooksReturn_0;
    address[] private _getRelayersReturn_0;
    bytes32 private _getRoleAdminReturn_0;
    bytes32 private _getSuperBankHookMerkleRootReturn_0;
    uint256 private _getSuperformManagersCountReturn_0;
    uint256 private _getUpkeepCostPerBatchUpdateReturn_0;
    address[] private _getValidatorsReturn_0;
    address private _getVaultBankReturn_0;
    bytes32 private _getVaultBankHookMerkleRootReturn_0;
    bool private _hasRoleReturn_0;
    bool private _isActivePPSOracleReturn_0;
    bool private _isExecutorReturn_0;
    bool private _isFulfillRequestsHookRegisteredReturn_0;
    bool private _isGuardianReturn_0;
    bool private _isHookRegisteredReturn_0;
    bool private _isManagerTakeoverFrozenReturn_0;
    bool private _isProtectedKeeperReturn_0;
    bool private _isRelayerReturn_0;
    bool private _isSuperformManagerReturn_0;
    bool private _isUpkeepPaymentsEnabledReturn_0;
    bool private _isValidatorReturn_0;
    bool private _isWhitelistedIncentiveTokenReturn_0;
    bool private _supportsInterfaceReturn_0;

    //<>=============================================================<>
    //||                                                             ||
    //||          ⚠️  VIEW FUNCTIONS - DO NOT MODIFY  ⚠️            ||
    //||                                                             ||
    //<>=============================================================<>
    // Mock implementation of BANK_MANAGER
    function BANK_MANAGER() public view returns (bytes32) {
        return _BANK_MANAGERReturn_0;
    }

    // Mock implementation of BANK_MANAGER_ROLE
    function BANK_MANAGER_ROLE() public view returns (bytes32) {
        return _BANK_MANAGER_ROLEReturn_0;
    }

    // Mock implementation of DEFAULT_ADMIN_ROLE
    function DEFAULT_ADMIN_ROLE() public view returns (bytes32) {
        return _DEFAULT_ADMIN_ROLEReturn_0;
    }

    // Mock implementation of ECDSAPPSORACLE
    function ECDSAPPSORACLE() public view returns (bytes32) {
        return _ECDSAPPSORACLEReturn_0;
    }

    // Mock implementation of GAS_MANAGER_ROLE
    function GAS_MANAGER_ROLE() public view returns (bytes32) {
        return _GAS_MANAGER_ROLEReturn_0;
    }

    // Mock implementation of GOVERNOR_ROLE
    function GOVERNOR_ROLE() public view returns (bytes32) {
        return _GOVERNOR_ROLEReturn_0;
    }

    // Mock implementation of GUARDIAN_ROLE
    function GUARDIAN_ROLE() public view returns (bytes32) {
        return _GUARDIAN_ROLEReturn_0;
    }

    // Mock implementation of SUP
    function SUP() public view returns (bytes32) {
        return _SUPReturn_0;
    }

    // Mock implementation of SUPER_ASSET_FACTORY
    function SUPER_ASSET_FACTORY() public view returns (bytes32) {
        return _SUPER_ASSET_FACTORYReturn_0;
    }

    // Mock implementation of SUPER_BANK
    function SUPER_BANK() public view returns (bytes32) {
        return _SUPER_BANKReturn_0;
    }

    // Mock implementation of SUPER_GOVERNOR_ROLE
    function SUPER_GOVERNOR_ROLE() public view returns (bytes32) {
        return _SUPER_GOVERNOR_ROLEReturn_0;
    }

    // Mock implementation of SUPER_ORACLE
    function SUPER_ORACLE() public view returns (bytes32) {
        return _SUPER_ORACLEReturn_0;
    }

    // Mock implementation of SUPER_VAULT_AGGREGATOR
    function SUPER_VAULT_AGGREGATOR() public view returns (bytes32) {
        return _SUPER_VAULT_AGGREGATORReturn_0;
    }

    // Mock implementation of TREASURY
    function TREASURY() public view returns (bytes32) {
        return _TREASURYReturn_0;
    }

    // Mock implementation of UP
    function UP() public view returns (bytes32) {
        return _UPReturn_0;
    }

    // Mock implementation of VAULT_BANK
    function VAULT_BANK() public view returns (bytes32) {
        return _VAULT_BANKReturn_0;
    }

    // Mock implementation of getActivePPSOracle
    function getActivePPSOracle() public view returns (address) {
        return _getActivePPSOracleReturn_0;
    }

    // Mock implementation of getAddress
    function getAddress(bytes32 key) public view returns (address) {
        return _getAddressReturn_0;
    }

    // Mock implementation of getAllSuperformManagers
    function getAllSuperformManagers() public view returns (address[] memory) {
        return _getAllSuperformManagersReturn_0;
    }

    // Mock implementation of getExecutors
    function getExecutors() public view returns (address[] memory) {
        return _getExecutorsReturn_0;
    }

    // Mock implementation of getFee
    function getFee(uint8 feeType) public view returns (uint256) {
        return _getFeeReturn_0;
    }

    // Mock implementation of getGasInfo
    function getGasInfo(
        address oracle_
    ) public view returns (ISuperGovernor_GasInfo memory) {
        return _getGasInfoReturn_0;
    }

    // Mock implementation of getManagersPaginated
    function getManagersPaginated(
        uint256 cursor,
        uint256 limit
    ) public view returns (address[] memory, uint256) {
        return (_getManagersPaginatedReturn_0, _getManagersPaginatedReturn_1);
    }

    // Mock implementation of getMinStaleness
    function getMinStaleness() public view returns (uint256) {
        return _getMinStalenessReturn_0;
    }

    // Mock implementation of getPPSOracleQuorum
    function getPPSOracleQuorum() public view returns (uint256) {
        return _getPPSOracleQuorumReturn_0;
    }

    // Mock implementation of getProposedActivePPSOracle
    function getProposedActivePPSOracle()
        public
        view
        returns (address, uint256)
    {
        return (
            _getProposedActivePPSOracleReturn_0,
            _getProposedActivePPSOracleReturn_1
        );
    }

    // Mock implementation of getProposedMinStaleness
    function getProposedMinStaleness() public view returns (uint256, uint256) {
        return (
            _getProposedMinStalenessReturn_0,
            _getProposedMinStalenessReturn_1
        );
    }

    // Mock implementation of getProposedSuperBankHookMerkleRoot
    function getProposedSuperBankHookMerkleRoot(
        address hook
    ) public view returns (bytes32, uint256) {
        return (
            _getProposedSuperBankHookMerkleRootReturn_0,
            _getProposedSuperBankHookMerkleRootReturn_1
        );
    }

    // Mock implementation of getProposedUpkeepPaymentsStatus
    function getProposedUpkeepPaymentsStatus()
        public
        view
        returns (bool, uint256)
    {
        return (
            _getProposedUpkeepPaymentsStatusReturn_0,
            _getProposedUpkeepPaymentsStatusReturn_1
        );
    }

    // Mock implementation of getProposedVaultBankHookMerkleRoot
    function getProposedVaultBankHookMerkleRoot(
        address hook
    ) public view returns (bytes32, uint256) {
        return (
            _getProposedVaultBankHookMerkleRootReturn_0,
            _getProposedVaultBankHookMerkleRootReturn_1
        );
    }

    // Mock implementation of getProtectedKeepers
    function getProtectedKeepers() public view returns (address[] memory) {
        return _getProtectedKeepersReturn_0;
    }

    // Mock implementation of getProtectedKeepersCount
    function getProtectedKeepersCount() public view returns (uint256) {
        return _getProtectedKeepersCountReturn_0;
    }

    // Mock implementation of getProver
    function getProver() public view returns (address) {
        return _getProverReturn_0;
    }

    // Mock implementation of getRegisteredFulfillRequestsHooks
    function getRegisteredFulfillRequestsHooks()
        public
        view
        returns (address[] memory)
    {
        return _getRegisteredFulfillRequestsHooksReturn_0;
    }

    // Mock implementation of getRegisteredHooks
    function getRegisteredHooks() public view returns (address[] memory) {
        return _getRegisteredHooksReturn_0;
    }

    // Mock implementation of getRelayers
    function getRelayers() public view returns (address[] memory) {
        return _getRelayersReturn_0;
    }

    // Mock implementation of getRoleAdmin
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _getRoleAdminReturn_0;
    }

    // Mock implementation of getSuperBankHookMerkleRoot
    function getSuperBankHookMerkleRoot(
        address hook
    ) public view returns (bytes32) {
        return _getSuperBankHookMerkleRootReturn_0;
    }

    // Mock implementation of getSuperformManagersCount
    function getSuperformManagersCount() public view returns (uint256) {
        return _getSuperformManagersCountReturn_0;
    }

    // Mock implementation of getUpkeepCostPerBatchUpdate
    function getUpkeepCostPerBatchUpdate(
        address oracle_,
        uint256 chargeableEntries_
    ) public view returns (uint256) {
        return _getUpkeepCostPerBatchUpdateReturn_0;
    }

    // Mock implementation of getValidators
    function getValidators() public view returns (address[] memory) {
        return _getValidatorsReturn_0;
    }

    // Mock implementation of getVaultBank
    function getVaultBank(uint64 chainId) public view returns (address) {
        return _getVaultBankReturn_0;
    }

    // Mock implementation of getVaultBankHookMerkleRoot
    function getVaultBankHookMerkleRoot(
        address hook
    ) public view returns (bytes32) {
        return _getVaultBankHookMerkleRootReturn_0;
    }

    // Mock implementation of hasRole
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _hasRoleReturn_0;
    }

    // Mock implementation of isActivePPSOracle
    function isActivePPSOracle(address oracle) public view returns (bool) {
        return _isActivePPSOracleReturn_0;
    }

    // Mock implementation of isExecutor
    function isExecutor(address executor) public view returns (bool) {
        return _isExecutorReturn_0;
    }

    // Mock implementation of isFulfillRequestsHookRegistered
    function isFulfillRequestsHookRegistered(
        address hook
    ) public view returns (bool) {
        return _isFulfillRequestsHookRegisteredReturn_0;
    }

    // Mock implementation of isGuardian
    function isGuardian(address guardian) public view returns (bool) {
        return _isGuardianReturn_0;
    }

    // Mock implementation of isHookRegistered
    function isHookRegistered(address hook) public view returns (bool) {
        return _isHookRegisteredReturn_0;
    }

    // Mock implementation of isManagerTakeoverFrozen
    function isManagerTakeoverFrozen() public view returns (bool) {
        return _isManagerTakeoverFrozenReturn_0;
    }

    // Mock implementation of isProtectedKeeper
    function isProtectedKeeper(address keeper) public view returns (bool) {
        return _isProtectedKeeperReturn_0;
    }

    // Mock implementation of isRelayer
    function isRelayer(address relayer) public view returns (bool) {
        return _isRelayerReturn_0;
    }

    // Mock implementation of isSuperformManager
    function isSuperformManager(address manager) public view returns (bool) {
        return _isSuperformManagerReturn_0;
    }

    // Mock implementation of isUpkeepPaymentsEnabled
    function isUpkeepPaymentsEnabled() public view returns (bool) {
        return _isUpkeepPaymentsEnabledReturn_0;
    }

    // Mock implementation of isValidator
    function isValidator(address validator) public view returns (bool) {
        return _isValidatorReturn_0;
    }

    // Mock implementation of isWhitelistedIncentiveToken
    function isWhitelistedIncentiveToken(
        address token
    ) public view returns (bool) {
        return _isWhitelistedIncentiveTokenReturn_0;
    }

    // Mock implementation of supportsInterface
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return _supportsInterfaceReturn_0;
    }
}
