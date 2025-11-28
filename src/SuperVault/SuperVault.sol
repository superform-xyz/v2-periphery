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
import { ISuperVault } from "../interfaces/SuperVault/ISuperVault.sol";
import { ISuperVaultStrategy } from "../interfaces/SuperVault/ISuperVaultStrategy.sol";
import { ISuperGovernor } from "../interfaces/ISuperGovernor.sol";
import { ISuperVaultAggregator } from "../interfaces/SuperVault/ISuperVaultAggregator.sol";
import { IERC7540Operator, IERC7540Redeem, IERC7540CancelRedeem } from "../vendor/standards/ERC7540/IERC7540Vault.sol";
import { IERC7741 } from "../vendor/standards/ERC7741/IERC7741.sol";
import { IERC7575 } from "../vendor/standards/ERC7575/IERC7575.sol";
import { ISuperVaultEscrow } from "../interfaces/SuperVault/ISuperVaultEscrow.sol";

// Libraries
import { AssetMetadataLib } from "../libraries/AssetMetadataLib.sol";

/// @title SuperVault
/// @author Superform Labs
/// @notice SuperVault vault contract implementing ERC4626 with synchronous deposits and asynchronous redeems via
/// ERC7540
contract SuperVault is Initializable, ERC20Upgradeable, ISuperVault, ReentrancyGuardUpgradeable, EIP712Upgradeable {
    using AssetMetadataLib for address;
    using SafeERC20 for IERC20;
    using Math for uint256;

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/
    uint256 private constant REQUEST_ID = 0;
    uint256 private constant BPS_PRECISION = 10_000;

    // EIP712 TypeHash
    /// @notice EIP-712 typehash for operator authorization signatures
    /// @dev Used to construct the digest for EIP-712 signature validation in authorizeOperator()
    ///      Format: "AuthorizeOperator(address controller,address operator,bool approved,bytes32 nonce,uint256
    // deadline)" /      - controller: The address authorizing the operator
    ///      - operator: The address being authorized/deauthorized
    ///      - approved: True to authorize, false to revoke
    ///      - nonce: Unique nonce for replay protection (one-time use)
    ///      - deadline: Timestamp after which signature expires
    /// @dev This typehash MUST remain constant. Any changes invalidate all existing signatures.
    /// @dev Off-chain signers must use this exact structure when creating signatures for authorizeOperator()
    bytes32 public constant AUTHORIZE_OPERATOR_TYPEHASH = keccak256(
        "AuthorizeOperator(address controller,address operator,bool approved,bytes32 nonce,uint256 deadline)"
    );

    /*//////////////////////////////////////////////////////////////
                                STATE
    //////////////////////////////////////////////////////////////*/
    address public share;
    IERC20 private _asset;
    uint8 private _underlyingDecimals;
    ISuperVaultStrategy public strategy;
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
    /// @dev This function can only be called once due to initializer modifier
    /// @dev SECURITY: asset, strategy, and escrow are pre-validated in SuperVaultAggregator.createVault()
    ///      to prevent initialization with invalid addresses. No additional validation needed here.
    /// @dev PRECISION is set to 10^decimals for consistent share/asset conversions
    /// @dev EIP-712 domain separator is initialized with vault name and version "1" for signature validation
    /// @param asset_ The underlying asset token address (pre-validated by aggregator)
    /// @param name_ The name of the vault token (used for ERC20 and EIP-712 domain)
    /// @param symbol_ The symbol of the vault token
    /// @param strategy_ The strategy contract address (pre-validated by aggregator)
    /// @param escrow_ The escrow contract address (pre-validated by aggregator)
    function initialize(
        address asset_,
        string memory name_,
        string memory symbol_,
        address strategy_,
        address escrow_
    )
        external
        initializer
    {
        /// @dev asset, strategy, and escrow already validated in SuperVaultAggregator during vault creation
        // Initialize parent contracts
        __ERC20_init(name_, symbol_);
        __ReentrancyGuard_init();
        __EIP712_init(name_, "1");

        // Set asset and precision
        _asset = IERC20(asset_);
        (bool success, uint8 assetDecimals) = asset_.tryGetAssetDecimals();
        if (!success) revert INVALID_ASSET();
        _underlyingDecimals = assetDecimals;
        PRECISION = 10 ** _underlyingDecimals;
        share = address(this);
        strategy = ISuperVaultStrategy(strategy_);
        escrow = escrow_;

        emit Initialized(asset_, strategy_, escrow_);
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                        USER EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IERC4626
    function deposit(uint256 assets, address receiver) public override nonReentrant returns (uint256 shares) {
        if (receiver == address(0)) revert ZERO_ADDRESS();
        if (assets == 0) revert ZERO_AMOUNT();

        // Forward assets from msg.sender to strategy
        _asset.safeTransferFrom(msg.sender, address(strategy), assets);

        // Single executor call: strategy skims entry fee, accounts on NET, returns net shares
        // Note: handleOperations4626Deposit already validates and reverts if shares == 0
        shares = strategy.handleOperations4626Deposit(receiver, assets);

        // Mint the net shares
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /// @inheritdoc IERC4626
    function mint(uint256 shares, address receiver) public override nonReentrant returns (uint256 assets) {
        if (receiver == address(0)) revert ZERO_ADDRESS();
        if (shares == 0) revert ZERO_AMOUNT();

        uint256 assetsNet;
        (assets, assetsNet) = strategy.quoteMintAssetsGross(shares);

        // Forward quoted gross assets from msg.sender to strategy
        _asset.safeTransferFrom(msg.sender, address(strategy), assets);

        // Single executor call: strategy handles fees and accounts on NET
        strategy.handleOperations4626Mint(receiver, shares, assets, assetsNet);

        // Mint the exact shares asked
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /// @inheritdoc IERC7540Redeem
    /// @notice Once owner has authorized an operator, controller must be the owner
    function requestRedeem(uint256 shares, address controller, address owner) external returns (uint256) {
        if (shares == 0) revert ZERO_AMOUNT();
        if (owner == address(0) || controller == address(0)) revert ZERO_ADDRESS();
        _validateController(owner);

        if (balanceOf(owner) < shares) revert INVALID_AMOUNT();
        if (strategy.pendingCancelRedeemRequest(owner)) revert CANCELLATION_REDEEM_REQUEST_PENDING();

        // Enforce auditor's invariant for current accounting model
        if (controller != owner) revert CONTROLLER_MUST_EQUAL_OWNER();

        // Transfer shares to escrow for temporary locking
        _approve(owner, escrow, shares);
        ISuperVaultEscrow(escrow).escrowShares(owner, shares);

        // Forward to strategy (7540 path)
        strategy.handleOperations7540(ISuperVaultStrategy.Operation.RedeemRequest, controller, address(0), shares);

        emit RedeemRequest(controller, owner, REQUEST_ID, msg.sender, shares);
        return REQUEST_ID;
    }

    /// @inheritdoc IERC7540CancelRedeem
    function cancelRedeemRequest(
        uint256,
        /*requestId*/
        address controller
    )
        external
    {
        _validateController(controller);

        // Forward to strategy (7540 path)
        strategy.handleOperations7540(ISuperVaultStrategy.Operation.CancelRedeemRequest, controller, address(0), 0);

        emit CancelRedeemRequest(controller, REQUEST_ID, msg.sender);
    }

    /// @inheritdoc IERC7540CancelRedeem
    function claimCancelRedeemRequest(
        uint256, /*requestId*/
        address receiver,
        address controller
    )
        external
        returns (uint256 shares)
    {
        if (receiver == address(0) || controller == address(0)) revert ZERO_ADDRESS();
        _validateControllerAndReceiver(controller, receiver);

        shares = strategy.claimableCancelRedeemRequest(controller);

        // Forward to strategy (7540 path)
        strategy.handleOperations7540(ISuperVaultStrategy.Operation.ClaimCancelRedeem, controller, address(0), 0);

        // Return shares to controller
        ISuperVaultEscrow(escrow).returnShares(receiver, shares);

        emit CancelRedeemClaim(receiver, controller, REQUEST_ID, msg.sender, shares);
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
        address controller,
        address operator,
        bool approved,
        bytes32 nonce,
        uint256 deadline,
        bytes memory signature
    )
        external
        returns (bool)
    {
        if (controller == operator) revert UNAUTHORIZED();
        if (block.timestamp > deadline) revert DEADLINE_PASSED();
        if (_authorizations[controller][nonce]) revert UNAUTHORIZED();

        _authorizations[controller][nonce] = true;

        bytes32 structHash =
            keccak256(abi.encode(AUTHORIZE_OPERATOR_TYPEHASH, controller, operator, approved, nonce, deadline));
        bytes32 digest = _hashTypedDataV4(structHash);

        if (!_isValidSignature(controller, digest, signature)) revert INVALID_SIGNATURE();

        isOperator[controller][operator] = approved;
        emit OperatorSet(controller, operator, approved);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                    USER EXTERNAL VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperVault
    function getEscrowedAssets() external view returns (uint256) {
        return _asset.balanceOf(escrow);
    }

    //--ERC7540--
    /// @inheritdoc IERC7540Redeem
    function pendingRedeemRequest(
        uint256, /*requestId*/
        address controller
    )
        external
        view
        returns (uint256 pendingShares)
    {
        return strategy.pendingRedeemRequest(controller);
    }

    /// @inheritdoc IERC7540Redeem
    function claimableRedeemRequest(
        uint256, /*requestId*/
        address controller
    )
        external
        view
        returns (uint256 claimableShares)
    {
        return maxRedeem(controller);
    }

    /// @inheritdoc IERC7540CancelRedeem
    function pendingCancelRedeemRequest(
        uint256,
        /*requestId*/
        address controller
    )
        external
        view
        returns (bool isPending)
    {
        isPending = strategy.pendingCancelRedeemRequest(controller);
    }

    /// @inheritdoc IERC7540CancelRedeem
    function claimableCancelRedeemRequest(
        uint256, /*requestId*/
        address controller
    )
        external
        view
        returns (uint256 claimableShares)
    {
        return strategy.claimableCancelRedeemRequest(controller);
    }

    //--Operator Management--

    /// @inheritdoc IERC7741
    function authorizations(address controller, bytes32 nonce) external view returns (bool used) {
        return _authorizations[controller][nonce];
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
    function maxDeposit(address) public view override returns (uint256) {
        if (!_canAcceptDeposits()) return 0;
        return type(uint256).max;
    }

    /// @inheritdoc IERC4626
    function maxMint(address) external view override returns (uint256) {
        if (!_canAcceptDeposits()) return 0;
        return type(uint256).max;
    }

    /// @inheritdoc IERC4626
    function maxWithdraw(address owner) public view override returns (uint256) {
        return strategy.claimableWithdraw(owner);
    }

    /// @inheritdoc IERC4626
    function maxRedeem(address owner) public view override returns (uint256) {
        uint256 withdrawPrice = strategy.getAverageWithdrawPrice(owner);
        if (withdrawPrice == 0) return 0;
        return maxWithdraw(owner).mulDiv(PRECISION, withdrawPrice, Math.Rounding.Floor);
    }

    /// @inheritdoc IERC4626
    function previewDeposit(uint256 assets) public view override returns (uint256) {
        uint256 pps = _getStoredPPS();
        if (pps == 0) return 0;

        (uint256 feeBps,) = _getManagementFeeConfig();

        if (feeBps == 0) return Math.mulDiv(assets, PRECISION, pps, Math.Rounding.Floor);
        // fee-on-gross: fee = ceil(gross * feeBps / BPS)
        uint256 fee = Math.mulDiv(assets, feeBps, BPS_PRECISION, Math.Rounding.Ceil);

        uint256 assetsNet = assets - fee;
        return Math.mulDiv(assetsNet, PRECISION, pps, Math.Rounding.Floor);
    }

    /// @inheritdoc IERC4626
    /// @dev Returns gross assets required to mint exact shares after management fees
    /// @dev Formula: gross = net * BPS_PRECISION / (BPS_PRECISION - feeBps)
    /// @dev Edge case: If feeBps >= 100% (10000), returns 0 (impossible to mint with 100%+ fees)
    ///      This prevents division by zero and represents mathematical impossibility.
    function previewMint(uint256 shares) public view override returns (uint256) {
        uint256 pps = _getStoredPPS();
        if (pps == 0) return 0;

        uint256 assetsGross = Math.mulDiv(shares, pps, PRECISION, Math.Rounding.Ceil);

        (uint256 feeBps,) = _getManagementFeeConfig();
        if (feeBps == 0) return assetsGross;
        if (feeBps >= BPS_PRECISION) return 0; // impossible to mint (would require infinite gross)

        return Math.mulDiv(assetsGross, BPS_PRECISION, (BPS_PRECISION - feeBps), Math.Rounding.Ceil);
    }

    /// @inheritdoc IERC4626
    function previewWithdraw(
        uint256 /* assets*/
    )
        public
        pure
        override
        returns (uint256)
    {
        revert NOT_IMPLEMENTED();
    }

    /// @inheritdoc IERC4626
    function previewRedeem(
        uint256 /* shares*/
    )
        public
        pure
        override
        returns (uint256)
    {
        revert NOT_IMPLEMENTED();
    }

    /// @inheritdoc IERC4626
    function withdraw(
        uint256 assets,
        address receiver,
        address controller
    )
        public
        override
        nonReentrant
        returns (uint256 shares)
    {
        if (receiver == address(0) || controller == address(0)) revert ZERO_ADDRESS();
        _validateControllerAndReceiver(controller, receiver);

        uint256 averageWithdrawPrice = strategy.getAverageWithdrawPrice(controller);
        if (averageWithdrawPrice == 0) revert INVALID_WITHDRAW_PRICE();

        uint256 maxWithdrawAmount = maxWithdraw(controller);
        if (assets > maxWithdrawAmount) revert INVALID_AMOUNT();

        // Calculate shares based on assets and average withdraw price
        shares = assets.mulDiv(PRECISION, averageWithdrawPrice, Math.Rounding.Ceil);

        uint256 escrowBalance = _asset.balanceOf(escrow);
        if (assets > escrowBalance) revert NOT_ENOUGH_ASSETS();

        // Update strategy state (7540 path)
        strategy.handleOperations7540(ISuperVaultStrategy.Operation.ClaimRedeem, controller, receiver, assets);

        // Transfer assets from escrow to receiver
        ISuperVaultEscrow(escrow).returnAssets(receiver, assets);

        emit Withdraw(msg.sender, receiver, controller, assets, shares);
    }

    /// @inheritdoc IERC4626
    function redeem(
        uint256 shares,
        address receiver,
        address controller
    )
        public
        override
        nonReentrant
        returns (uint256 assets)
    {
        if (receiver == address(0) || controller == address(0)) revert ZERO_ADDRESS();
        _validateControllerAndReceiver(controller, receiver);

        uint256 averageWithdrawPrice = strategy.getAverageWithdrawPrice(controller);
        if (averageWithdrawPrice == 0) revert INVALID_WITHDRAW_PRICE();

        // Calculate assets based on shares and average withdraw price
        assets = shares.mulDiv(averageWithdrawPrice, PRECISION, Math.Rounding.Floor);

        uint256 maxWithdrawAmount = maxWithdraw(controller);
        if (assets > maxWithdrawAmount) revert INVALID_AMOUNT();

        uint256 escrowBalance = _asset.balanceOf(escrow);
        if (assets > escrowBalance) revert NOT_ENOUGH_ASSETS();

        // Update strategy state (7540 path)
        strategy.handleOperations7540(ISuperVaultStrategy.Operation.ClaimRedeem, controller, receiver, assets);

        // Transfer assets from escrow to receiver
        ISuperVaultEscrow(escrow).returnAssets(receiver, assets);

        emit Withdraw(msg.sender, receiver, controller, assets, shares);
    }

    /// @inheritdoc ISuperVault
    function burnShares(uint256 amount) external {
        if (msg.sender != address(strategy)) revert UNAUTHORIZED();
        _burn(escrow, amount);
    }

    /*//////////////////////////////////////////////////////////////
                            ERC165 INTERFACE
    //////////////////////////////////////////////////////////////*/
    /// @notice Checks if contract supports a given interface
    /// @dev Implements ERC165 for ERC7540, ERC7741, ERC4626, ERC7575 support detection
    /// @param interfaceId The interface identifier to check
    /// @return True if the interface is supported, false otherwise
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == type(IERC7540Redeem).interfaceId || interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IERC7741).interfaceId || interfaceId == type(IERC4626).interfaceId
            || interfaceId == type(IERC7575).interfaceId || interfaceId == type(IERC7540Operator).interfaceId;
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Validates that the caller is authorized to act on behalf of the controller
    /// @dev Enforces ERC7540Operator pattern: either direct call from controller or authorized operator
    /// @dev Operators must be authorized via setOperator() or authorizeOperator() (EIP-712 signature)
    /// @dev Used in redemption flows to prevent unauthorized claims
    /// @param controller The controller address to validate authorization for
    /// @dev Reverts with INVALID_CONTROLLER if:
    ///      - caller is not the controller AND
    ///      - caller is not an authorized operator for the controller
    function _validateController(address controller) internal view {
        if (controller != msg.sender && !_isOperator(controller, msg.sender)) revert INVALID_CONTROLLER();
    }

    /// @notice Validates controller authorization and enforces operator receiver restrictions
    /// @dev Controllers can set any receiver; operators must set receiver == controller
    /// @param controller The controller address to validate authorization for
    /// @param receiver The receiver address to validate against operator restrictions
    function _validateControllerAndReceiver(address controller, address receiver) internal view {
        // If caller is controller, all good
        if (controller == msg.sender) return;

        // Caller is not controller, must be operator
        if (!_isOperator(controller, msg.sender)) revert INVALID_CONTROLLER();

        // Caller is operator, enforce receiver == controller
        if (receiver != controller) revert RECEIVER_MUST_EQUAL_CONTROLLER();
    }

    function _isOperator(address controller, address operator) internal view returns (bool) {
        return isOperator[controller][operator];
    }

    /// @notice Verify an EIP712 signature using OpenZeppelin's ECDSA library
    /// @param signer The signer to verify
    /// @param digest The digest to verify
    /// @param signature The signature to verify
    function _isValidSignature(address signer, bytes32 digest, bytes memory signature) internal pure returns (bool) {
        address recoveredSigner = ECDSA.recover(digest, signature);
        return recoveredSigner == signer;
    }

    function _getStoredPPS() internal view returns (uint256) {
        return strategy.getStoredPPS();
    }

    /// @notice Combined check for deposits acceptance
    /// @dev Reduces external calls by fetching aggregator address once
    /// @dev Previously: 4 external calls (2x getAddress + 2x aggregator checks)
    /// @dev Now: 3 external calls (1x getAddress + 2x aggregator checks)
    /// @return True if deposits can be accepted (not paused and PPS not stale)
    function _canAcceptDeposits() internal view returns (bool) {
        address aggregatorAddress = _getAggregatorAddress();
        ISuperVaultAggregator aggregator = ISuperVaultAggregator(aggregatorAddress);
        return !aggregator.isStrategyPaused(address(strategy)) && !aggregator.isPPSStale(address(strategy));
    }

    /// @notice Helper to get aggregator address once
    /// @return Address of the SuperVaultAggregator contract
    function _getAggregatorAddress() internal view returns (address) {
        return SUPER_GOVERNOR.getAddress(SUPER_GOVERNOR.SUPER_VAULT_AGGREGATOR());
    }

    /// @dev Read management fee config (view-only for previews)
    function _getManagementFeeConfig() internal view returns (uint256 feeBps, address recipient) {
        ISuperVaultStrategy.FeeConfig memory cfg = strategy.getConfigInfo();
        return (cfg.managementFeeBps, cfg.recipient);
    }
}
