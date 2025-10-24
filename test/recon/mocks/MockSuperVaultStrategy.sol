// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract MockSuperVaultStrategy {
    //<>=============================================================<>
    //||                                                             ||
    //||                    NON-VIEW FUNCTIONS                       ||
    //||                                                             ||
    //<>=============================================================<>
    // Mock implementation of executeHooks
    function executeHooks(
        ISuperVaultStrategy_ExecuteArgs memory args
    ) public payable {}

    // Mock implementation of executeVaultFeeConfigUpdate
    function executeVaultFeeConfigUpdate() public {}

    // Mock implementation of fulfillRedeemRequests
    function fulfillRedeemRequests(
        ISuperVaultStrategy_FulfillArgs memory args
    ) public {}

    // Mock implementation of handleOperations4626Mint
    function handleOperations4626Mint(
        address controller,
        uint256 sharesNet,
        uint256 assetsGross,
        uint256 assetsNet
    ) public {}

    // Mock implementation of handleOperations7540
    function handleOperations7540(
        uint8 operation,
        address controller,
        address receiver,
        uint256 amount
    ) public {}

    // Mock implementation of initialize
    function initialize(
        address vaultAddress,
        ISuperVaultStrategy_FeeConfig memory feeConfigData
    ) public {}

    // Mock implementation of manageEmergencyWithdraw
    function manageEmergencyWithdraw(
        uint8 action,
        address recipient,
        uint256 amount
    ) public {}

    // Mock implementation of manageYieldSource
    function manageYieldSource(
        address source,
        address oracle,
        uint8 actionType
    ) public {}

    // Mock implementation of manageYieldSources
    function manageYieldSources(
        address[] memory sources,
        address[] memory oracles,
        uint8[] memory actionTypes
    ) public {}

    // Mock implementation of moveAccumulatorOnTransfer
    function moveAccumulatorOnTransfer(
        address from,
        address to,
        uint256 shares
    ) public {}

    // Mock implementation of proposeVaultFeeConfigUpdate
    function proposeVaultFeeConfigUpdate(
        uint256 performanceFeeBps,
        uint256 managementFeeBps,
        address recipient
    ) public {}

    // Mock implementation of updateMaxPPSSlippage
    function updateMaxPPSSlippage(uint256 maxSlippageBps) public {}

    // Mock implementation of receive function
    receive() external payable {}

    //<>=============================================================<>
    //||                                                             ||
    //||                    SETTER FUNCTIONS                         ||
    //||                                                             ||
    //<>=============================================================<>
    // Function to set return values for PRECISION
    function setPRECISIONReturn(uint256 _value0) public {
        _PRECISIONReturn_0 = _value0;
    }

    // Function to set return values for claimableWithdraw
    function setClaimableWithdrawReturn(uint256 _value0) public {
        _claimableWithdrawReturn_0 = _value0;
    }

    // Function to set return values for containsYieldSource
    function setContainsYieldSourceReturn(bool _value0) public {
        _containsYieldSourceReturn_0 = _value0;
    }

    // Function to set return values for emergencyWithdrawable
    function setEmergencyWithdrawableReturn(bool _value0) public {
        _emergencyWithdrawableReturn_0 = _value0;
    }

    // Function to set return values for emergencyWithdrawableEffectiveTime
    function setEmergencyWithdrawableEffectiveTimeReturn(
        uint256 _value0
    ) public {
        _emergencyWithdrawableEffectiveTimeReturn_0 = _value0;
    }

    // Function to set return values for getAverageWithdrawPrice
    function setGetAverageWithdrawPriceReturn(uint256 _value0) public {
        _getAverageWithdrawPriceReturn_0 = _value0;
    }

    // Function to set return values for getConfigInfo
    function setGetConfigInfoReturn(
        ISuperVaultStrategy_FeeConfig memory _value0
    ) public {
        _getConfigInfoReturn_0 = _value0;
    }

    // Function to set return values for getStoredPPS
    function setGetStoredPPSReturn(uint256 _value0) public {
        _getStoredPPSReturn_0 = _value0;
    }

    // Function to set return values for getSuperVaultState
    function setGetSuperVaultStateReturn(
        ISuperVaultStrategy_SuperVaultState memory _value0
    ) public {
        _getSuperVaultStateReturn_0 = _value0;
    }

    // Function to set return values for getVaultInfo
    function setGetVaultInfoReturn(
        address _value0,
        address _value1,
        uint8 _value2
    ) public {
        _getVaultInfoReturn_0 = _value0;
        _getVaultInfoReturn_1 = _value1;
        _getVaultInfoReturn_2 = _value2;
    }

    // Function to set return values for getYieldSource
    function setGetYieldSourceReturn(
        ISuperVaultStrategy_YieldSource memory _value0
    ) public {
        _getYieldSourceReturn_0 = _value0;
    }

    // Function to set return values for getYieldSources
    function setGetYieldSourcesReturn(address[] memory _value0) public {
        delete _getYieldSourcesReturn_0;
        for (uint i = 0; i < _value0.length; i++) {
            _getYieldSourcesReturn_0.push(_value0[i]);
        }
    }

    // Function to set return values for getYieldSourcesCount
    function setGetYieldSourcesCountReturn(uint256 _value0) public {
        _getYieldSourcesCountReturn_0 = _value0;
    }

    // Function to set return values for getYieldSourcesList
    function setGetYieldSourcesListReturn(
        ISuperVaultStrategy_YieldSourceInfo[] memory _value0
    ) public {
        delete _getYieldSourcesListReturn_0;
        for (uint i = 0; i < _value0.length; i++) {
            _getYieldSourcesListReturn_0.push(_value0[i]);
        }
    }

    // Function to set return values for handleOperations4626Deposit
    function setHandleOperations4626DepositReturn(uint256 _value0) public {
        _handleOperations4626DepositReturn_0 = _value0;
    }

    // Function to set return values for pendingRedeemRequest
    function setPendingRedeemRequestReturn(uint256 _value0) public {
        _pendingRedeemRequestReturn_0 = _value0;
    }

    // Function to set return values for previewPerformanceFee
    function setPreviewPerformanceFeeReturn(
        uint256 _value0,
        uint256 _value1,
        uint256 _value2
    ) public {
        _previewPerformanceFeeReturn_0 = _value0;
        _previewPerformanceFeeReturn_1 = _value1;
        _previewPerformanceFeeReturn_2 = _value2;
    }

    // Function to set return values for proposedEmergencyWithdrawable
    function setProposedEmergencyWithdrawableReturn(bool _value0) public {
        _proposedEmergencyWithdrawableReturn_0 = _value0;
    }

    // Function to set return values for quoteMintAssetsGross
    function setQuoteMintAssetsGrossReturn(
        uint256 _value0,
        uint256 _value1
    ) public {
        _quoteMintAssetsGrossReturn_0 = _value0;
        _quoteMintAssetsGrossReturn_1 = _value1;
    }

    // Function to set return values for superGovernor
    function setSuperGovernorReturn(address _value0) public {
        _superGovernorReturn_0 = _value0;
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
    // Struct definition for ISuperVaultStrategy_ExecuteArgs
    struct ISuperVaultStrategy_ExecuteArgs {
        address[] hooks;
        bytes[] hookCalldata;
        uint256[] expectedAssetsOrSharesOut;
        bytes32[][] globalProofs;
        bytes32[][] strategyProofs;
    }

    // Struct definition for ISuperVaultStrategy_FulfillArgs
    struct ISuperVaultStrategy_FulfillArgs {
        address[] controllers;
        address[] hooks;
        bytes[] hookCalldata;
        uint256[] expectedAssetsOrSharesOut;
        bytes32[][] globalProofs;
        bytes32[][] strategyProofs;
    }

    // Struct definition for ISuperVaultStrategy_FeeConfig
    struct ISuperVaultStrategy_FeeConfig {
        uint256 performanceFeeBps;
        uint256 managementFeeBps;
        address recipient;
    }

    // Struct definition for ISuperVaultStrategy_SuperVaultState
    struct ISuperVaultStrategy_SuperVaultState {
        uint256 pendingRedeemRequest;
        uint256 maxWithdraw;
        uint256 averageRequestPPS;
        uint256 accumulatorShares;
        uint256 accumulatorCostBasis;
        uint256 averageWithdrawPrice;
    }

    // Struct definition for ISuperVaultStrategy_YieldSource
    struct ISuperVaultStrategy_YieldSource {
        address oracle;
    }

    // Struct definition for ISuperVaultStrategy_YieldSourceInfo
    struct ISuperVaultStrategy_YieldSourceInfo {
        address sourceAddress;
        address oracle;
    }

    //<>=============================================================<>
    //||                                                             ||
    //||        ⚠️  EVENTS DEFINITIONS - DO NOT MODIFY  ⚠️          ||
    //||                                                             ||
    //<>=============================================================<>
    event DepositHandled(address controller, uint256 assets, uint256 shares);
    event EmergencyWithdrawableProposalCanceled();
    event EmergencyWithdrawableProposed(
        bool newWithdrawable,
        uint256 effectiveTime
    );
    event EmergencyWithdrawableUpdated(bool withdrawable);
    event EmergencyWithdrawal(address recipient, uint256 assets);
    event FeePaid(address recipient, uint256 amount, uint256 performanceFeeBps);
    event FulfillHookExecuted(
        address hook,
        address targetedYieldSource,
        bytes hookCalldata
    );
    event HookExecuted(
        address hook,
        address prevHook,
        address targetedYieldSource,
        bool usePrevHookAmount,
        bytes hookCalldata
    );
    event HookRootProposed(bytes32 proposedRoot, uint256 effectiveTime);
    event HookRootUpdated(bytes32 newRoot);
    event HooksExecuted(address[] hooks);
    event Initialized(uint64 version);
    event Initialized(address vault);
    event ManagementFeePaid(
        address controller,
        address recipient,
        uint256 feeAssets,
        uint256 feeBps
    );
    event MaxPPSSlippageUpdated(uint256 maxSlippageBps);
    event PPSUpdated(uint256 newPPS, uint256 calculationBlock);
    event RedeemRequestCanceled(address controller, uint256 shares);
    event RedeemRequestFulfilled(
        address controller,
        address receiver,
        uint256 assets,
        uint256 shares
    );
    event RedeemRequestPlaced(
        address controller,
        address owner,
        uint256 shares
    );
    event RedeemRequestsFulfilled(
        address[] hooks,
        address[] controllers,
        uint256 processedShares,
        uint256 currentPPS
    );
    event SuperGovernorSet(address superGovernor);
    event VaultFeeConfigProposed(
        uint256 performanceFeeBps,
        uint256 managementFeeBps,
        address recipient,
        uint256 effectiveTime
    );
    event VaultFeeConfigUpdated(
        uint256 performanceFeeBps,
        uint256 managementFeeBps,
        address recipient
    );
    event YieldSourceAdded(address source, address oracle);
    event YieldSourceOracleUpdated(
        address source,
        address oldOracle,
        address newOracle
    );
    event YieldSourceRemoved(address source);

    //<>=============================================================<>
    //||                                                             ||
    //||         ⚠️  INTERNAL STORAGE - DO NOT MODIFY  ⚠️           ||
    //||                                                             ||
    //<>=============================================================<>
    uint256 private _PRECISIONReturn_0;
    uint256 private _claimableWithdrawReturn_0;
    bool private _containsYieldSourceReturn_0;
    bool private _emergencyWithdrawableReturn_0;
    uint256 private _emergencyWithdrawableEffectiveTimeReturn_0;
    uint256 private _getAverageWithdrawPriceReturn_0;
    ISuperVaultStrategy_FeeConfig private _getConfigInfoReturn_0;
    uint256 private _getStoredPPSReturn_0;
    ISuperVaultStrategy_SuperVaultState private _getSuperVaultStateReturn_0;
    address private _getVaultInfoReturn_0;
    address private _getVaultInfoReturn_1;
    uint8 private _getVaultInfoReturn_2;
    ISuperVaultStrategy_YieldSource private _getYieldSourceReturn_0;
    address[] private _getYieldSourcesReturn_0;
    uint256 private _getYieldSourcesCountReturn_0;
    ISuperVaultStrategy_YieldSourceInfo[] private _getYieldSourcesListReturn_0;
    uint256 private _handleOperations4626DepositReturn_0;
    uint256 private _pendingRedeemRequestReturn_0;
    uint256 private _previewPerformanceFeeReturn_0;
    uint256 private _previewPerformanceFeeReturn_1;
    uint256 private _previewPerformanceFeeReturn_2;
    bool private _proposedEmergencyWithdrawableReturn_0;
    uint256 private _quoteMintAssetsGrossReturn_0;
    uint256 private _quoteMintAssetsGrossReturn_1;
    address private _superGovernorReturn_0;

    //<>=============================================================<>
    //||                                                             ||
    //||          ⚠️  VIEW FUNCTIONS - DO NOT MODIFY  ⚠️            ||
    //||                                                             ||
    //<>=============================================================<>
    // Mock implementation of PRECISION
    function PRECISION() public view returns (uint256) {
        return _PRECISIONReturn_0;
    }

    // Mock implementation of claimableWithdraw
    function claimableWithdraw(
        address controller
    ) public view returns (uint256) {
        return _claimableWithdrawReturn_0;
    }

    // Mock implementation of containsYieldSource
    function containsYieldSource(address source) public view returns (bool) {
        return _containsYieldSourceReturn_0;
    }

    // Mock implementation of emergencyWithdrawable
    function emergencyWithdrawable() public view returns (bool) {
        return _emergencyWithdrawableReturn_0;
    }

    // Mock implementation of emergencyWithdrawableEffectiveTime
    function emergencyWithdrawableEffectiveTime()
        public
        view
        returns (uint256)
    {
        return _emergencyWithdrawableEffectiveTimeReturn_0;
    }

    // Mock implementation of getAverageWithdrawPrice
    function getAverageWithdrawPrice(
        address controller
    ) public view returns (uint256) {
        return _getAverageWithdrawPriceReturn_0;
    }

    // Mock implementation of getConfigInfo
    function getConfigInfo()
        public
        view
        returns (ISuperVaultStrategy_FeeConfig memory)
    {
        return _getConfigInfoReturn_0;
    }

    // Mock implementation of getStoredPPS
    function getStoredPPS() public view returns (uint256) {
        return _getStoredPPSReturn_0;
    }

    // Mock implementation of getSuperVaultState
    function getSuperVaultState(
        address controller
    ) public view returns (ISuperVaultStrategy_SuperVaultState memory) {
        return _getSuperVaultStateReturn_0;
    }

    // Mock implementation of getVaultInfo
    function getVaultInfo() public view returns (address, address, uint8) {
        return (
            _getVaultInfoReturn_0,
            _getVaultInfoReturn_1,
            _getVaultInfoReturn_2
        );
    }

    // Mock implementation of getYieldSource
    function getYieldSource(
        address source
    ) public view returns (ISuperVaultStrategy_YieldSource memory) {
        return _getYieldSourceReturn_0;
    }

    // Mock implementation of getYieldSources
    function getYieldSources() public view returns (address[] memory) {
        return _getYieldSourcesReturn_0;
    }

    // Mock implementation of getYieldSourcesCount
    function getYieldSourcesCount() public view returns (uint256) {
        return _getYieldSourcesCountReturn_0;
    }

    // Mock implementation of getYieldSourcesList
    function getYieldSourcesList()
        public
        view
        returns (ISuperVaultStrategy_YieldSourceInfo[] memory)
    {
        return _getYieldSourcesListReturn_0;
    }

    // Mock implementation of handleOperations4626Deposit
    function handleOperations4626Deposit(
        address controller,
        uint256 assetsGross
    ) public view returns (uint256) {
        return _handleOperations4626DepositReturn_0;
    }

    // Mock implementation of pendingRedeemRequest
    function pendingRedeemRequest(
        address controller
    ) public view returns (uint256) {
        return _pendingRedeemRequestReturn_0;
    }

    // Mock implementation of previewPerformanceFee
    function previewPerformanceFee(
        address controller,
        uint256 sharesToRedeem
    ) public view returns (uint256, uint256, uint256) {
        return (
            _previewPerformanceFeeReturn_0,
            _previewPerformanceFeeReturn_1,
            _previewPerformanceFeeReturn_2
        );
    }

    // Mock implementation of proposedEmergencyWithdrawable
    function proposedEmergencyWithdrawable() public view returns (bool) {
        return _proposedEmergencyWithdrawableReturn_0;
    }

    // Mock implementation of quoteMintAssetsGross
    function quoteMintAssetsGross(
        uint256 shares
    ) public view returns (uint256, uint256) {
        return (_quoteMintAssetsGrossReturn_0, _quoteMintAssetsGrossReturn_1);
    }

    // Mock implementation of superGovernor
    function superGovernor() public view returns (address) {
        return _superGovernorReturn_0;
    }
}
