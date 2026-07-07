// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

// External
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";

// OpenZeppelin Upgradeable
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

// Interfaces
import { IManagedSuperVault } from "../interfaces/ManagedSuperVault/IManagedSuperVault.sol";
import { IManagedSuperVaultController } from "../interfaces/ManagedSuperVault/IManagedSuperVaultController.sol";
import { IManagedSuperVaultEscrow } from "../interfaces/ManagedSuperVault/IManagedSuperVaultEscrow.sol";
import { ISuperGovernor } from "../interfaces/ISuperGovernor.sol";
import {
    IERC7540Operator,
    IERC7540Deposit,
    IERC7540Redeem,
    IERC7540CancelDeposit,
    IERC7540CancelRedeem
} from "../vendor/standards/ERC7540/IERC7540Vault.sol";
import { IERC7741 } from "../vendor/standards/ERC7741/IERC7741.sol";

// Libraries
import { AssetMetadataLib } from "../libraries/AssetMetadataLib.sol";

/// @title ManagedSuperVault
/// @author Superform Labs
/// @notice Managed Vault share token implementing fully-asynchronous ERC-7540 deposits and redemptions.
///         Synchronous ERC-4626 deposit/mint paths are unavailable and revert with NOT_IMPLEMENTED.
/// @dev Share conversions use the latest attested manual NAV/PPS. Pending deposit assets are held in
///      escrow until the manager fulfills or the depositor cancels; deposit cancellation is instantly
///      fulfilled since pending assets are never deployed.
contract ManagedSuperVault is
    Initializable,
    ERC20Upgradeable,
    IManagedSuperVault,
    ReentrancyGuardUpgradeable,
    EIP712Upgradeable
{
    using AssetMetadataLib for address;
    using SafeERC20 for IERC20;
    using Math for uint256;

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/
    uint256 private constant REQUEST_ID = 0;

    /// @notice EIP-712 typehash for operator authorization signatures (identical to SuperVault)
    bytes32 public constant AUTHORIZE_OPERATOR_TYPEHASH = keccak256(
        "AuthorizeOperator(address controller,address operator,bool approved,bytes32 nonce,uint256 deadline)"
    );

    /*//////////////////////////////////////////////////////////////
                                STATE
    //////////////////////////////////////////////////////////////*/
    address public share;
    IERC20 private _asset;
    uint8 private _underlyingDecimals;
    IManagedSuperVaultController public controller;
    address public escrow;
    uint256 public PRECISION;

    // Core contracts
    ISuperGovernor public immutable SUPER_GOVERNOR;

    /// @inheritdoc IERC7540Operator
    mapping(address owner => mapping(address operator => bool)) public isOperator;

    // Authorization tracking
    mapping(address controller => mapping(bytes32 nonce => bool used)) private _authorizations;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address superGovernor_) {
        if (superGovernor_ == address(0)) revert ZERO_ADDRESS();
        SUPER_GOVERNOR = ISuperGovernor(superGovernor_);
        emit SuperGovernorSet(superGovernor_);

        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Initialize the vault with required parameters
    /// @dev asset, controller, and escrow are pre-validated in ManagedSuperVaultAggregator.createManagedVault()
    /// @param asset_ The underlying asset token address
    /// @param name_ The name of the vault token (used for ERC20 and EIP-712 domain)
    /// @param symbol_ The symbol of the vault token
    /// @param controller_ The controller contract address
    /// @param escrow_ The escrow contract address
    function initialize(
        address asset_,
        string memory name_,
        string memory symbol_,
        address controller_,
        address escrow_
    )
        external
        initializer
    {
        __ERC20_init(name_, symbol_);
        __ReentrancyGuard_init();
        __EIP712_init(name_, "1");

        _asset = IERC20(asset_);
        (bool success, uint8 assetDecimals) = asset_.tryGetAssetDecimals();
        if (!success) revert INVALID_ASSET();
        _underlyingDecimals = assetDecimals;
        PRECISION = 10 ** _underlyingDecimals;
        share = address(this);
        controller = IManagedSuperVaultController(controller_);
        escrow = escrow_;

        emit Initialized(asset_, controller_, escrow_);
    }

    /*//////////////////////////////////////////////////////////////
                    SYNCHRONOUS PATHS: UNAVAILABLE
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC4626
    /// @dev Managed Vaults are fully async: the synchronous ERC-4626 deposit path is unavailable
    function deposit(uint256, address) public pure override returns (uint256) {
        revert NOT_IMPLEMENTED();
    }

    /// @inheritdoc IERC4626
    /// @dev Managed Vaults are fully async: the synchronous ERC-4626 mint path is unavailable
    function mint(uint256, address) public pure override returns (uint256) {
        revert NOT_IMPLEMENTED();
    }

    /*//////////////////////////////////////////////////////////////
                        ASYNC DEPOSIT FLOW
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC7540Deposit
    /// @notice Transfers assets from owner into escrow and submits an async deposit request
    /// @dev controller MUST equal owner (accounting invariant, mirrors the redeem side)
    function requestDeposit(uint256 assets, address controller_, address owner)
        external
        nonReentrant
        returns (uint256)
    {
        if (assets == 0) revert ZERO_AMOUNT();
        if (owner == address(0) || controller_ == address(0)) revert ZERO_ADDRESS();
        _validateController(owner);

        // Enforce accounting invariant for the per-controller request model
        if (controller_ != owner) revert CONTROLLER_MUST_EQUAL_OWNER();

        // Validate policy/approval/state and update request accounting
        controller.handleDepositRequest(controller_, assets);

        // Transfer assets from owner into escrow custody
        _asset.safeTransferFrom(owner, escrow, assets);

        emit DepositRequest(controller_, owner, REQUEST_ID, msg.sender, assets);
        return REQUEST_ID;
    }

    /// @inheritdoc IERC7540CancelDeposit
    /// @notice Cancels a pending deposit request with instant fulfillment: assets are refunded
    ///         from escrow to the controller in the same transaction
    function cancelDepositRequest(
        uint256,
        /*requestId*/
        address controller_
    )
        external
        nonReentrant
    {
        _validateController(controller_);

        uint256 assets = controller.handleCancelDepositRequest(controller_);

        // Refund assets from escrow to the controller
        IManagedSuperVaultEscrow(escrow).refundDepositAssets(controller_, assets);

        emit CancelDepositRequest(controller_, REQUEST_ID, msg.sender);
        emit CancelDepositClaim(controller_, controller_, REQUEST_ID, msg.sender, assets);
    }

    /// @inheritdoc IERC7540CancelDeposit
    /// @dev Deposit cancellations are instantly fulfilled; there is never a pending cancellation
    function pendingCancelDepositRequest(uint256, address) external pure returns (bool) {
        return false;
    }

    /// @inheritdoc IERC7540CancelDeposit
    /// @dev Deposit cancellations are instantly fulfilled and auto-claimed; nothing is ever claimable
    function claimableCancelDepositRequest(uint256, address) external pure returns (uint256) {
        return 0;
    }

    /// @inheritdoc IERC7540CancelDeposit
    /// @dev Deposit cancellations are instantly fulfilled and auto-claimed in cancelDepositRequest
    function claimCancelDepositRequest(uint256, address, address) external pure returns (uint256) {
        revert NOT_IMPLEMENTED();
    }

    /// @inheritdoc IERC7540Deposit
    /// @notice Claim step: mints shares for fulfilled (claimable) deposit assets at the average deposit price
    function deposit(
        uint256 assets,
        address receiver,
        address controller_
    )
        public
        nonReentrant
        returns (uint256 shares)
    {
        if (receiver == address(0) || controller_ == address(0)) revert ZERO_ADDRESS();
        if (assets == 0) revert ZERO_AMOUNT();
        _validateControllerAndReceiver(controller_, receiver);

        uint256 averageDepositPrice = controller.getAverageDepositPrice(controller_);
        if (averageDepositPrice == 0) revert INVALID_DEPOSIT_PRICE();

        if (assets > controller.claimableDepositRequest(controller_)) revert INVALID_AMOUNT();

        shares = assets.mulDiv(PRECISION, averageDepositPrice, Math.Rounding.Floor);
        if (shares == 0) revert INVALID_AMOUNT();

        controller.handleClaimDeposit(controller_, assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /// @inheritdoc IERC7540Deposit
    /// @notice Claim step: mints exact shares for fulfilled (claimable) deposit assets
    function mint(uint256 shares, address receiver, address controller_) public nonReentrant returns (uint256 assets) {
        if (receiver == address(0) || controller_ == address(0)) revert ZERO_ADDRESS();
        if (shares == 0) revert ZERO_AMOUNT();
        _validateControllerAndReceiver(controller_, receiver);

        uint256 averageDepositPrice = controller.getAverageDepositPrice(controller_);
        if (averageDepositPrice == 0) revert INVALID_DEPOSIT_PRICE();

        assets = shares.mulDiv(averageDepositPrice, PRECISION, Math.Rounding.Ceil);
        if (assets == 0 || assets > controller.claimableDepositRequest(controller_)) revert INVALID_AMOUNT();

        controller.handleClaimDeposit(controller_, assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /// @inheritdoc IERC7540Deposit
    function pendingDepositRequest(
        uint256,
        /*requestId*/
        address controller_
    )
        external
        view
        returns (uint256 pendingAssets)
    {
        return controller.pendingDepositRequest(controller_);
    }

    /// @inheritdoc IERC7540Deposit
    function claimableDepositRequest(
        uint256,
        /*requestId*/
        address controller_
    )
        external
        view
        returns (uint256 claimableAssets)
    {
        return controller.claimableDepositRequest(controller_);
    }

    /*//////////////////////////////////////////////////////////////
                        ASYNC REDEEM FLOW
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC7540Redeem
    /// @notice Once owner has authorized an operator, controller must be the owner
    function requestRedeem(uint256 shares, address controller_, address owner) external returns (uint256) {
        if (shares == 0) revert ZERO_AMOUNT();
        if (owner == address(0) || controller_ == address(0)) revert ZERO_ADDRESS();
        _validateController(owner);

        if (balanceOf(owner) < shares) revert INVALID_AMOUNT();
        if (controller.pendingCancelRedeemRequest(owner)) revert CANCELLATION_REDEEM_REQUEST_PENDING();

        // Enforce accounting invariant (mirrors SuperVault)
        if (controller_ != owner) revert CONTROLLER_MUST_EQUAL_OWNER();

        // Transfer shares to escrow for temporary locking
        _approve(owner, escrow, shares);
        IManagedSuperVaultEscrow(escrow).escrowShares(owner, shares);

        // Forward to controller (7540 path)
        controller.handleOperations7540(
            IManagedSuperVaultController.Operation.RedeemRequest, controller_, address(0), shares
        );

        emit RedeemRequest(controller_, owner, REQUEST_ID, msg.sender, shares);
        return REQUEST_ID;
    }

    /// @inheritdoc IERC7540CancelRedeem
    function cancelRedeemRequest(
        uint256,
        /*requestId*/
        address controller_
    )
        external
    {
        _validateController(controller_);

        controller.handleOperations7540(
            IManagedSuperVaultController.Operation.CancelRedeemRequest, controller_, address(0), 0
        );

        emit CancelRedeemRequest(controller_, REQUEST_ID, msg.sender);
    }

    /// @inheritdoc IERC7540CancelRedeem
    function claimCancelRedeemRequest(
        uint256, /*requestId*/
        address receiver,
        address controller_
    )
        external
        returns (uint256 shares)
    {
        if (receiver == address(0) || controller_ == address(0)) revert ZERO_ADDRESS();
        _validateControllerAndReceiver(controller_, receiver);

        shares = controller.claimableCancelRedeemRequest(controller_);

        controller.handleOperations7540(
            IManagedSuperVaultController.Operation.ClaimCancelRedeem, controller_, address(0), 0
        );

        // Return shares to receiver
        IManagedSuperVaultEscrow(escrow).returnShares(receiver, shares);

        emit CancelRedeemClaim(receiver, controller_, REQUEST_ID, msg.sender, shares);
    }

    /// @inheritdoc IERC7540Operator
    function setOperator(address operator, bool approved) external returns (bool success) {
        if (msg.sender == operator) revert UNAUTHORIZED();
        isOperator[msg.sender][operator] = approved;
        emit OperatorSet(msg.sender, operator, approved);
        return true;
    }

    /// @inheritdoc IERC7741
    function authorizeOperator(
        address controller_,
        address operator,
        bool approved,
        bytes32 nonce,
        uint256 deadline,
        bytes memory signature
    )
        external
        returns (bool)
    {
        if (controller_ == operator) revert UNAUTHORIZED();
        if (block.timestamp > deadline) revert DEADLINE_PASSED();
        if (_authorizations[controller_][nonce]) revert UNAUTHORIZED();

        _authorizations[controller_][nonce] = true;

        bytes32 structHash =
            keccak256(abi.encode(AUTHORIZE_OPERATOR_TYPEHASH, controller_, operator, approved, nonce, deadline));
        bytes32 digest = _hashTypedDataV4(structHash);

        if (!_isValidSignature(controller_, digest, signature)) revert INVALID_SIGNATURE();

        isOperator[controller_][operator] = approved;
        emit OperatorSet(controller_, operator, approved);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                    USER EXTERNAL VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IManagedSuperVault
    function getEscrowedAssets() external view returns (uint256) {
        return _asset.balanceOf(escrow);
    }

    //--ERC7540--
    /// @inheritdoc IERC7540Redeem
    function pendingRedeemRequest(
        uint256, /*requestId*/
        address controller_
    )
        external
        view
        returns (uint256 pendingShares)
    {
        return controller.pendingRedeemRequest(controller_);
    }

    /// @inheritdoc IERC7540Redeem
    function claimableRedeemRequest(
        uint256, /*requestId*/
        address controller_
    )
        external
        view
        returns (uint256 claimableShares)
    {
        return maxRedeem(controller_);
    }

    /// @inheritdoc IERC7540CancelRedeem
    function pendingCancelRedeemRequest(
        uint256,
        /*requestId*/
        address controller_
    )
        external
        view
        returns (bool isPending)
    {
        isPending = controller.pendingCancelRedeemRequest(controller_);
    }

    /// @inheritdoc IERC7540CancelRedeem
    function claimableCancelRedeemRequest(
        uint256, /*requestId*/
        address controller_
    )
        external
        view
        returns (uint256 claimableShares)
    {
        return controller.claimableCancelRedeemRequest(controller_);
    }

    //--Operator Management--

    /// @inheritdoc IERC7741
    function authorizations(address controller_, bytes32 nonce) external view returns (bool used) {
        return _authorizations[controller_][nonce];
    }

    /// @inheritdoc IERC7741
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return _domainSeparatorV4();
    }

    /// @inheritdoc IERC7741
    function invalidateNonce(bytes32 nonce) external {
        if (_authorizations[msg.sender][nonce]) revert INVALID_NONCE();
        _authorizations[msg.sender][nonce] = true;

        emit NonceInvalidated(msg.sender, nonce);
    }

    /*//////////////////////////////////////////////////////////////
                            ERC4626 IMPLEMENTATION
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IERC20Metadata
    function decimals() public view virtual override(ERC20Upgradeable, IERC20Metadata) returns (uint8) {
        return _underlyingDecimals;
    }

    /// @inheritdoc IERC4626
    function asset() public view virtual override returns (address) {
        return address(_asset);
    }

    /// @inheritdoc IERC4626
    function totalAssets() external view override returns (uint256) {
        uint256 supply = totalSupply();
        if (supply == 0) return 0;
        uint256 currentPPS = _getStoredPPS();
        return Math.mulDiv(supply, currentPPS, PRECISION, Math.Rounding.Floor);
    }

    /// @inheritdoc IERC4626
    function convertToShares(uint256 assets) public view override returns (uint256) {
        uint256 pps = _getStoredPPS();
        return pps == 0 ? 0 : Math.mulDiv(assets, PRECISION, pps, Math.Rounding.Floor);
    }

    /// @inheritdoc IERC4626
    function convertToAssets(uint256 shares) public view override returns (uint256) {
        uint256 currentPPS = _getStoredPPS();
        return currentPPS == 0 ? 0 : Math.mulDiv(shares, currentPPS, PRECISION, Math.Rounding.Floor);
    }

    /// @inheritdoc IERC4626
    /// @dev ERC-7540 semantics: max claimable (fulfilled) deposit assets for the controller
    function maxDeposit(address controller_) public view override returns (uint256) {
        return controller.claimableDepositRequest(controller_);
    }

    /// @inheritdoc IERC4626
    /// @dev ERC-7540 semantics: max shares mintable from claimable deposit assets
    function maxMint(address controller_) external view override returns (uint256) {
        uint256 averageDepositPrice = controller.getAverageDepositPrice(controller_);
        if (averageDepositPrice == 0) return 0;
        return maxDeposit(controller_).mulDiv(PRECISION, averageDepositPrice, Math.Rounding.Floor);
    }

    /// @inheritdoc IERC4626
    function maxWithdraw(address owner) public view override returns (uint256) {
        return controller.claimableWithdraw(owner);
    }

    /// @inheritdoc IERC4626
    function maxRedeem(address owner) public view override returns (uint256) {
        uint256 withdrawPrice = controller.getAverageWithdrawPrice(owner);
        if (withdrawPrice == 0) return 0;
        return maxWithdraw(owner).mulDiv(PRECISION, withdrawPrice, Math.Rounding.Floor);
    }

    /// @inheritdoc IERC4626
    /// @dev ERC-7540: preview functions MUST revert for async flows
    function previewDeposit(
        uint256 /*assets*/
    )
        public
        pure
        override
        returns (uint256)
    {
        revert NOT_IMPLEMENTED();
    }

    /// @inheritdoc IERC4626
    /// @dev ERC-7540: preview functions MUST revert for async flows
    function previewMint(
        uint256 /*shares*/
    )
        public
        pure
        override
        returns (uint256)
    {
        revert NOT_IMPLEMENTED();
    }

    /// @inheritdoc IERC4626
    /// @dev ERC-7540: preview functions MUST revert for async flows
    function previewWithdraw(
        uint256 /*assets*/
    )
        public
        pure
        override
        returns (uint256)
    {
        revert NOT_IMPLEMENTED();
    }

    /// @inheritdoc IERC4626
    /// @dev ERC-7540: preview functions MUST revert for async flows
    function previewRedeem(
        uint256 /*shares*/
    )
        public
        pure
        override
        returns (uint256)
    {
        revert NOT_IMPLEMENTED();
    }

    /// @inheritdoc IERC4626
    /// @notice Claim step for fulfilled redemptions at the average withdraw price
    function withdraw(
        uint256 assets,
        address receiver,
        address controller_
    )
        public
        override
        nonReentrant
        returns (uint256 shares)
    {
        if (receiver == address(0) || controller_ == address(0)) revert ZERO_ADDRESS();
        _validateControllerAndReceiver(controller_, receiver);

        uint256 averageWithdrawPrice = controller.getAverageWithdrawPrice(controller_);
        if (averageWithdrawPrice == 0) revert INVALID_WITHDRAW_PRICE();

        uint256 maxWithdrawAmount = maxWithdraw(controller_);
        if (assets > maxWithdrawAmount) revert INVALID_AMOUNT();

        shares = assets.mulDiv(PRECISION, averageWithdrawPrice, Math.Rounding.Ceil);

        if (assets > _redeemableEscrowBalance()) revert NOT_ENOUGH_ASSETS();

        controller.handleOperations7540(
            IManagedSuperVaultController.Operation.ClaimRedeem, controller_, receiver, assets
        );

        IManagedSuperVaultEscrow(escrow).returnAssets(receiver, assets);

        emit Withdraw(msg.sender, receiver, controller_, assets, shares);
    }

    /// @inheritdoc IERC4626
    /// @notice Claim step for fulfilled redemptions at the average withdraw price
    function redeem(
        uint256 shares,
        address receiver,
        address controller_
    )
        public
        override
        nonReentrant
        returns (uint256 assets)
    {
        if (receiver == address(0) || controller_ == address(0)) revert ZERO_ADDRESS();
        _validateControllerAndReceiver(controller_, receiver);

        uint256 averageWithdrawPrice = controller.getAverageWithdrawPrice(controller_);
        if (averageWithdrawPrice == 0) revert INVALID_WITHDRAW_PRICE();

        assets = shares.mulDiv(averageWithdrawPrice, PRECISION, Math.Rounding.Floor);

        uint256 maxWithdrawAmount = maxWithdraw(controller_);
        if (assets > maxWithdrawAmount) revert INVALID_AMOUNT();

        if (assets > _redeemableEscrowBalance()) revert NOT_ENOUGH_ASSETS();

        controller.handleOperations7540(
            IManagedSuperVaultController.Operation.ClaimRedeem, controller_, receiver, assets
        );

        IManagedSuperVaultEscrow(escrow).returnAssets(receiver, assets);

        emit Withdraw(msg.sender, receiver, controller_, assets, shares);
    }

    /// @inheritdoc IManagedSuperVault
    function burnShares(uint256 amount) external {
        if (msg.sender != address(controller)) revert UNAUTHORIZED();
        _burn(escrow, amount);
    }

    /*//////////////////////////////////////////////////////////////
                            ERC165 INTERFACE
    //////////////////////////////////////////////////////////////*/
    /// @notice Checks if contract supports a given interface
    /// @dev Advertises the fully-async ERC-7540 surface. IERC4626 is intentionally not advertised
    ///      because the synchronous deposit/mint paths revert.
    /// @param interfaceId The interface identifier to check
    /// @return True if the interface is supported, false otherwise
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == type(IERC7540Deposit).interfaceId || interfaceId == type(IERC7540Redeem).interfaceId
            || interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC7741).interfaceId
            || interfaceId == type(IERC7540Operator).interfaceId
            || interfaceId == type(IERC7540CancelDeposit).interfaceId
            || interfaceId == type(IERC7540CancelRedeem).interfaceId;
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Validates that the caller is authorized to act on behalf of the controller
    /// @dev Enforces ERC7540Operator pattern: either direct call from controller or authorized operator
    function _validateController(address controller_) internal view {
        if (controller_ != msg.sender && !_isOperator(controller_, msg.sender)) revert INVALID_CONTROLLER();
    }

    /// @notice Validates controller authorization and enforces operator receiver restrictions
    /// @dev Controllers can set any receiver; operators must set receiver == controller
    function _validateControllerAndReceiver(address controller_, address receiver) internal view {
        if (controller_ == msg.sender) return;

        if (!_isOperator(controller_, msg.sender)) revert INVALID_CONTROLLER();

        if (receiver != controller_) revert RECEIVER_MUST_EQUAL_CONTROLLER();
    }

    function _isOperator(address controller_, address operator) internal view returns (bool) {
        return isOperator[controller_][operator];
    }

    /// @notice Verify an EIP712 signature using OpenZeppelin's ECDSA library
    function _isValidSignature(address signer, bytes32 digest, bytes memory signature) internal pure returns (bool) {
        address recoveredSigner = ECDSA.recover(digest, signature);
        return recoveredSigner == signer;
    }

    function _getStoredPPS() internal view returns (uint256) {
        return controller.getStoredPPS();
    }

    /// @notice Escrow asset balance available for redemption claims
    /// @dev Excludes pending deposit assets held in escrow custody so redemption claims can never
    ///      consume unfulfilled deposit requests
    function _redeemableEscrowBalance() internal view returns (uint256) {
        uint256 escrowBalance = _asset.balanceOf(escrow);
        uint256 pendingDeposits = controller.totalPendingDepositAssets();
        return escrowBalance > pendingDeposits ? escrowBalance - pendingDeposits : 0;
    }
}
