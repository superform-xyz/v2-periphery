// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract MockSuperVault {
    //<>=============================================================<>
    //||                                                             ||
    //||                    NON-VIEW FUNCTIONS                       ||
    //||                                                             ||
    //<>=============================================================<>
    // Mock implementation of burnShares
    function burnShares(uint256 amount) public {}

    // Mock implementation of cancelRedeem
    function cancelRedeem(address controller) public {}

    // Mock implementation of initialize
    function initialize(
        address asset_,
        string memory name_,
        string memory symbol_,
        address strategy_,
        address escrow_
    ) public {}

    // Mock implementation of invalidateNonce
    function invalidateNonce(bytes32 nonce) public {}

    // Mock implementation of onRedeemClaimable
    function onRedeemClaimable(
        address user,
        uint256 assets,
        uint256 shares,
        uint256 averageWithdrawPrice,
        uint256 accumulatorShares,
        uint256 accumulatorCostBasis
    ) public {}

    //<>=============================================================<>
    //||                                                             ||
    //||                    SETTER FUNCTIONS                         ||
    //||                                                             ||
    //<>=============================================================<>
    // Function to set return values for AUTHORIZE_OPERATOR_TYPEHASH
    function setAUTHORIZE_OPERATOR_TYPEHASHReturn(bytes32 _value0) public {
        _AUTHORIZE_OPERATOR_TYPEHASHReturn_0 = _value0;
    }

    // Function to set return values for DOMAIN_SEPARATOR
    function setDOMAIN_SEPARATORReturn(bytes32 _value0) public {
        _DOMAIN_SEPARATORReturn_0 = _value0;
    }

    // Function to set return values for PRECISION
    function setPRECISIONReturn(uint256 _value0) public {
        _PRECISIONReturn_0 = _value0;
    }

    // Function to set return values for allowance
    function setAllowanceReturn(uint256 _value0) public {
        _allowanceReturn_0 = _value0;
    }

    // Function to set return values for approve
    function setApproveReturn(bool _value0) public {
        _approveReturn_0 = _value0;
    }

    // Function to set return values for asset
    function setAssetReturn(address _value0) public {
        _assetReturn_0 = _value0;
    }

    // Function to set return values for authorizations
    function setAuthorizationsReturn(bool _value0) public {
        _authorizationsReturn_0 = _value0;
    }

    // Function to set return values for authorizeOperator
    function setAuthorizeOperatorReturn(bool _value0) public {
        _authorizeOperatorReturn_0 = _value0;
    }

    // Function to set return values for balanceOf
    function setBalanceOfReturn(uint256 _value0) public {
        _balanceOfReturn_0 = _value0;
    }

    // Function to set return values for claimableRedeemRequest
    function setClaimableRedeemRequestReturn(uint256 _value0) public {
        _claimableRedeemRequestReturn_0 = _value0;
    }

    // Function to set return values for convertToAssets
    function setConvertToAssetsReturn(uint256 _value0) public {
        _convertToAssetsReturn_0 = _value0;
    }

    // Function to set return values for convertToShares
    function setConvertToSharesReturn(uint256 _value0) public {
        _convertToSharesReturn_0 = _value0;
    }

    // Function to set return values for decimals
    function setDecimalsReturn(uint8 _value0) public {
        _decimalsReturn_0 = _value0;
    }

    // Function to set return values for deposit
    function setDepositReturn(uint256 _value0) public {
        _depositReturn_0 = _value0;
    }

    // Function to set return values for eip712Domain
    function setEip712DomainReturn(
        bytes1 _value0,
        string memory _value1,
        string memory _value2,
        uint256 _value3,
        address _value4,
        bytes32 _value5,
        uint256[] memory _value6
    ) public {
        _eip712DomainReturn_0 = _value0;
        _eip712DomainReturn_1 = _value1;
        _eip712DomainReturn_2 = _value2;
        _eip712DomainReturn_3 = _value3;
        _eip712DomainReturn_4 = _value4;
        _eip712DomainReturn_5 = _value5;
        delete _eip712DomainReturn_6;
        for (uint i = 0; i < _value6.length; i++) {
            _eip712DomainReturn_6.push(_value6[i]);
        }
    }

    // Function to set return values for escrow
    function setEscrowReturn(address _value0) public {
        _escrowReturn_0 = _value0;
    }

    // Function to set return values for isOperator
    function setIsOperatorReturn(bool _value0) public {
        _isOperatorReturn_0 = _value0;
    }

    // Function to set return values for maxDeposit
    function setMaxDepositReturn(uint256 _value0) public {
        _maxDepositReturn_0 = _value0;
    }

    // Function to set return values for maxMint
    function setMaxMintReturn(uint256 _value0) public {
        _maxMintReturn_0 = _value0;
    }

    // Function to set return values for maxRedeem
    function setMaxRedeemReturn(uint256 _value0) public {
        _maxRedeemReturn_0 = _value0;
    }

    // Function to set return values for maxWithdraw
    function setMaxWithdrawReturn(uint256 _value0) public {
        _maxWithdrawReturn_0 = _value0;
    }

    // Function to set return values for mint
    function setMintReturn(uint256 _value0) public {
        _mintReturn_0 = _value0;
    }

    // Function to set return values for name
    function setNameReturn(string memory _value0) public {
        _nameReturn_0 = _value0;
    }

    // Function to set return values for pendingRedeemRequest
    function setPendingRedeemRequestReturn(uint256 _value0) public {
        _pendingRedeemRequestReturn_0 = _value0;
    }

    // Function to set return values for previewDeposit
    function setPreviewDepositReturn(uint256 _value0) public {
        _previewDepositReturn_0 = _value0;
    }

    // Function to set return values for previewMint
    function setPreviewMintReturn(uint256 _value0) public {
        _previewMintReturn_0 = _value0;
    }

    // Function to set return values for previewRedeem
    function setPreviewRedeemReturn(uint256 _value0) public {
        _previewRedeemReturn_0 = _value0;
    }

    // Function to set return values for previewWithdraw
    function setPreviewWithdrawReturn(uint256 _value0) public {
        _previewWithdrawReturn_0 = _value0;
    }

    // Function to set return values for redeem
    function setRedeemReturn(uint256 _value0) public {
        _redeemReturn_0 = _value0;
    }

    // Function to set return values for requestRedeem
    function setRequestRedeemReturn(uint256 _value0) public {
        _requestRedeemReturn_0 = _value0;
    }

    // Function to set return values for setOperator
    function setSetOperatorReturn(bool _value0) public {
        _setOperatorReturn_0 = _value0;
    }

    // Function to set return values for share
    function setShareReturn(address _value0) public {
        _shareReturn_0 = _value0;
    }

    // Function to set return values for strategy
    function setStrategyReturn(address _value0) public {
        _strategyReturn_0 = _value0;
    }

    // Function to set return values for superGovernor
    function setSuperGovernorReturn(address _value0) public {
        _superGovernorReturn_0 = _value0;
    }

    // Function to set return values for supportsInterface
    function setSupportsInterfaceReturn(bool _value0) public {
        _supportsInterfaceReturn_0 = _value0;
    }

    // Function to set return values for symbol
    function setSymbolReturn(string memory _value0) public {
        _symbolReturn_0 = _value0;
    }

    // Function to set return values for totalAssets
    function setTotalAssetsReturn(uint256 _value0) public {
        _totalAssetsReturn_0 = _value0;
    }

    // Function to set return values for totalSupply
    function setTotalSupplyReturn(uint256 _value0) public {
        _totalSupplyReturn_0 = _value0;
    }

    // Function to set return values for transfer
    function setTransferReturn(bool _value0) public {
        _transferReturn_0 = _value0;
    }

    // Function to set return values for transferFrom
    function setTransferFromReturn(bool _value0) public {
        _transferFromReturn_0 = _value0;
    }

    // Function to set return values for withdraw
    function setWithdrawReturn(uint256 _value0) public {
        _withdrawReturn_0 = _value0;
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

    //<>=============================================================<>
    //||                                                             ||
    //||        ⚠️  EVENTS DEFINITIONS - DO NOT MODIFY  ⚠️          ||
    //||                                                             ||
    //<>=============================================================<>
    event Approval(address owner, address spender, uint256 value);
    event Deposit(
        address sender,
        address owner,
        uint256 assets,
        uint256 shares
    );
    event EIP712DomainChanged();
    event Initialized(uint64 version);
    event NonceInvalidated(address sender, bytes32 nonce);
    event OperatorSet(address controller, address operator, bool approved);
    event RedeemClaimable(
        address user,
        uint256 requestId,
        uint256 assets,
        uint256 shares,
        uint256 averageWithdrawPrice,
        uint256 accumulatorShares,
        uint256 accumulatorCostBasis
    );
    event RedeemRequest(
        address controller,
        address owner,
        uint256 requestId,
        address sender,
        uint256 assets
    );
    event RedeemRequestCancelled(address controller, address sender);
    event SuperGovernorSet(address superGovernor);
    event Transfer(address from, address to, uint256 value);
    event Withdraw(
        address sender,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    );

    //<>=============================================================<>
    //||                                                             ||
    //||         ⚠️  INTERNAL STORAGE - DO NOT MODIFY  ⚠️           ||
    //||                                                             ||
    //<>=============================================================<>
    bytes32 private _AUTHORIZE_OPERATOR_TYPEHASHReturn_0;
    bytes32 private _DOMAIN_SEPARATORReturn_0;
    uint256 private _PRECISIONReturn_0;
    uint256 private _allowanceReturn_0;
    bool private _approveReturn_0;
    address private _assetReturn_0;
    bool private _authorizationsReturn_0;
    bool private _authorizeOperatorReturn_0;
    uint256 private _balanceOfReturn_0;
    uint256 private _claimableRedeemRequestReturn_0;
    uint256 private _convertToAssetsReturn_0;
    uint256 private _convertToSharesReturn_0;
    uint8 private _decimalsReturn_0;
    uint256 private _depositReturn_0;
    bytes1 private _eip712DomainReturn_0;
    string private _eip712DomainReturn_1;
    string private _eip712DomainReturn_2;
    uint256 private _eip712DomainReturn_3;
    address private _eip712DomainReturn_4;
    bytes32 private _eip712DomainReturn_5;
    uint256[] private _eip712DomainReturn_6;
    address private _escrowReturn_0;
    bool private _isOperatorReturn_0;
    uint256 private _maxDepositReturn_0;
    uint256 private _maxMintReturn_0;
    uint256 private _maxRedeemReturn_0;
    uint256 private _maxWithdrawReturn_0;
    uint256 private _mintReturn_0;
    string private _nameReturn_0;
    uint256 private _pendingRedeemRequestReturn_0;
    uint256 private _previewDepositReturn_0;
    uint256 private _previewMintReturn_0;
    uint256 private _previewRedeemReturn_0;
    uint256 private _previewWithdrawReturn_0;
    uint256 private _redeemReturn_0;
    uint256 private _requestRedeemReturn_0;
    bool private _setOperatorReturn_0;
    address private _shareReturn_0;
    address private _strategyReturn_0;
    address private _superGovernorReturn_0;
    bool private _supportsInterfaceReturn_0;
    string private _symbolReturn_0;
    uint256 private _totalAssetsReturn_0;
    uint256 private _totalSupplyReturn_0;
    bool private _transferReturn_0;
    bool private _transferFromReturn_0;
    uint256 private _withdrawReturn_0;

    //<>=============================================================<>
    //||                                                             ||
    //||          ⚠️  VIEW FUNCTIONS - DO NOT MODIFY  ⚠️            ||
    //||                                                             ||
    //<>=============================================================<>
    // Mock implementation of AUTHORIZE_OPERATOR_TYPEHASH
    function AUTHORIZE_OPERATOR_TYPEHASH() public view returns (bytes32) {
        return _AUTHORIZE_OPERATOR_TYPEHASHReturn_0;
    }

    // Mock implementation of DOMAIN_SEPARATOR
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return _DOMAIN_SEPARATORReturn_0;
    }

    // Mock implementation of PRECISION
    function PRECISION() public view returns (uint256) {
        return _PRECISIONReturn_0;
    }

    // Mock implementation of allowance
    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return _allowanceReturn_0;
    }

    // Mock implementation of approve
    function approve(
        address spender,
        uint256 value
    ) public view returns (bool) {
        return _approveReturn_0;
    }

    // Mock implementation of asset
    function asset() public view returns (address) {
        return _assetReturn_0;
    }

    // Mock implementation of authorizations
    function authorizations(
        address controller,
        bytes32 nonce
    ) public view returns (bool) {
        return _authorizationsReturn_0;
    }

    // Mock implementation of authorizeOperator
    function authorizeOperator(
        address controller,
        address operator,
        bool approved,
        bytes32 nonce,
        uint256 deadline,
        bytes memory signature
    ) public view returns (bool) {
        return _authorizeOperatorReturn_0;
    }

    // Mock implementation of balanceOf
    function balanceOf(address account) public view returns (uint256) {
        return _balanceOfReturn_0;
    }

    // Mock implementation of claimableRedeemRequest
    function claimableRedeemRequest(
        uint256 arg0,
        address controller
    ) public view returns (uint256) {
        return _claimableRedeemRequestReturn_0;
    }

    // Mock implementation of convertToAssets
    function convertToAssets(uint256 shares) public view returns (uint256) {
        return _convertToAssetsReturn_0;
    }

    // Mock implementation of convertToShares
    function convertToShares(uint256 assets) public view returns (uint256) {
        return _convertToSharesReturn_0;
    }

    // Mock implementation of decimals
    function decimals() public view returns (uint8) {
        return _decimalsReturn_0;
    }

    // Mock implementation of deposit
    function deposit(
        uint256 assets,
        address receiver
    ) public view returns (uint256) {
        return _depositReturn_0;
    }

    // Mock implementation of eip712Domain
    function eip712Domain()
        public
        view
        returns (
            bytes1,
            string memory,
            string memory,
            uint256,
            address,
            bytes32,
            uint256[] memory
        )
    {
        return (
            _eip712DomainReturn_0,
            _eip712DomainReturn_1,
            _eip712DomainReturn_2,
            _eip712DomainReturn_3,
            _eip712DomainReturn_4,
            _eip712DomainReturn_5,
            _eip712DomainReturn_6
        );
    }

    // Mock implementation of escrow
    function escrow() public view returns (address) {
        return _escrowReturn_0;
    }

    // Mock implementation of isOperator
    function isOperator(
        address owner,
        address operator
    ) public view returns (bool) {
        return _isOperatorReturn_0;
    }

    // Mock implementation of maxDeposit
    function maxDeposit(address arg0) public view returns (uint256) {
        return _maxDepositReturn_0;
    }

    // Mock implementation of maxMint
    function maxMint(address arg0) public view returns (uint256) {
        return _maxMintReturn_0;
    }

    // Mock implementation of maxRedeem
    function maxRedeem(address owner) public view returns (uint256) {
        return _maxRedeemReturn_0;
    }

    // Mock implementation of maxWithdraw
    function maxWithdraw(address owner) public view returns (uint256) {
        return _maxWithdrawReturn_0;
    }

    // Mock implementation of mint
    function mint(
        uint256 shares,
        address receiver
    ) public view returns (uint256) {
        return _mintReturn_0;
    }

    // Mock implementation of name
    function name() public view returns (string memory) {
        return _nameReturn_0;
    }

    // Mock implementation of pendingRedeemRequest
    function pendingRedeemRequest(
        uint256 arg0,
        address controller
    ) public view returns (uint256) {
        return _pendingRedeemRequestReturn_0;
    }

    // Mock implementation of previewDeposit
    function previewDeposit(uint256 assets) public view returns (uint256) {
        return _previewDepositReturn_0;
    }

    // Mock implementation of previewMint
    function previewMint(uint256 shares) public view returns (uint256) {
        return _previewMintReturn_0;
    }

    // Mock implementation of previewRedeem
    function previewRedeem(uint256 arg0) public view returns (uint256) {
        return _previewRedeemReturn_0;
    }

    // Mock implementation of previewWithdraw
    function previewWithdraw(uint256 arg0) public view returns (uint256) {
        return _previewWithdrawReturn_0;
    }

    // Mock implementation of redeem
    function redeem(
        uint256 shares,
        address receiver,
        address controller
    ) public view returns (uint256) {
        return _redeemReturn_0;
    }

    // Mock implementation of requestRedeem
    function requestRedeem(
        uint256 shares,
        address controller,
        address owner
    ) public view returns (uint256) {
        return _requestRedeemReturn_0;
    }

    // Mock implementation of setOperator
    function setOperator(
        address operator,
        bool approved
    ) public view returns (bool) {
        return _setOperatorReturn_0;
    }

    // Mock implementation of share
    function share() public view returns (address) {
        return _shareReturn_0;
    }

    // Mock implementation of strategy
    function strategy() public view returns (address) {
        return _strategyReturn_0;
    }

    // Mock implementation of superGovernor
    function superGovernor() public view returns (address) {
        return _superGovernorReturn_0;
    }

    // Mock implementation of supportsInterface
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return _supportsInterfaceReturn_0;
    }

    // Mock implementation of symbol
    function symbol() public view returns (string memory) {
        return _symbolReturn_0;
    }

    // Mock implementation of totalAssets
    function totalAssets() public view returns (uint256) {
        return _totalAssetsReturn_0;
    }

    // Mock implementation of totalSupply
    function totalSupply() public view returns (uint256) {
        return _totalSupplyReturn_0;
    }

    // Mock implementation of transfer
    function transfer(address to, uint256 value) public view returns (bool) {
        return _transferReturn_0;
    }

    // Mock implementation of transferFrom
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public view returns (bool) {
        return _transferFromReturn_0;
    }

    // Mock implementation of withdraw
    function withdraw(
        uint256 assets,
        address receiver,
        address controller
    ) public view returns (uint256) {
        return _withdrawReturn_0;
    }
}
