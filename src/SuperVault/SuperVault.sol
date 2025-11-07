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
    ISuperGovernor public immutable superGovernor;

    /// @inheritdoc IERC7540Operator
    mapping(address owner => mapping(address operator => bool)) public isOperator;

    // Authorization tracking
    mapping(address controller => mapping(bytes32 nonce => bool used)) private _authorizations;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address superGovernor_) {
        if (superGovernor_ == address(0)) revert ZERO_ADDRESS();
        superGovernor = ISuperGovernor(superGovernor_);
        emit SuperGovernorSet(superGovernor_);

        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Initialize the vault with required parameters
    /// @param asset_ The underlying asset token address
    /// @param name_ The name of the vault token
    /// @param symbol_ The symbol of the vault token
    /// @param strategy_ The strategy contract address
    /// @param escrow_ The escrow contract address
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
        if (asset_ == address(0)) revert INVALID_ASSET();
        if (strategy_ == address(0)) revert INVALID_STRATEGY();
        if (escrow_ == address(0)) revert INVALID_ESCROW();

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

        // Forward assets from msg-sender to strategy
        _asset.safeTransferFrom(msg.sender, address(strategy), assets);

        // Single executor call: strategy skims entry fee, accounts on NET, returns net shares
        shares = strategy.handleOperations4626Deposit(receiver, assets);
        if (shares == 0) revert ZERO_AMOUNT();

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

        // Forward quoted gross assets from msg-sender to strategy
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
        if (owner != msg.sender && !isOperator[owner][msg.sender]) revert INVALID_OWNER_OR_OPERATOR();

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
        _validateController(controller);
        if (receiver == address(0) || controller == address(0)) revert ZERO_ADDRESS();
        if (controller != msg.sender && !isOperator[controller][msg.sender]) revert INVALID_OWNER_OR_OPERATOR();
        if (receiver != controller) revert INVALID_CONTROLLER();

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
                            STRATEGY RELATED
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperVault
    function extractAndSendAssets(address to, uint256 assets) external {
        if (msg.sender != address(strategy)) revert UNAUTHORIZED();
        uint256 escrowBalance = _asset.balanceOf(escrow);
        if (assets > escrowBalance) revert NOT_ENOUGH_ASSETS();

        ISuperVaultEscrow(escrow).returnAssets(to, assets);
    }

    /*//////////////////////////////////////////////////////////////
                            ERC4626 IMPLEMENTATION
    //////////////////////////////////////////////////////////////*/
    function decimals() public view virtual override(ERC20Upgradeable, IERC20Metadata) returns (uint8) {
        return _underlyingDecimals;
    }

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
        if (pps == 0) return 0;
        return Math.mulDiv(assets, PRECISION, pps, Math.Rounding.Floor);
    }

    /// @inheritdoc IERC4626
    function convertToAssets(uint256 shares) public view override returns (uint256) {
        uint256 currentPPS = _getStoredPPS();
        if (currentPPS == 0) return 0;
        return Math.mulDiv(shares, currentPPS, PRECISION, Math.Rounding.Floor);
    }

    /// @inheritdoc IERC4626
    function maxDeposit(address) public view override returns (uint256) {
        if (_isPaused() || _isPPSStale()) return 0;
        return type(uint256).max;
    }

    /// @inheritdoc IERC4626
    function maxMint(address) external view override returns (uint256) {
        if (_isPaused() || _isPPSStale()) return 0;
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
    function previewMint(uint256 shares) public view override returns (uint256) {
        uint256 pps = _getStoredPPS();
        if (pps == 0) return 0;

        uint256 assetsNet = Math.mulDiv(shares, pps, PRECISION, Math.Rounding.Ceil);

        (uint256 feeBps,) = _getManagementFeeConfig();
        if (feeBps == 0) return assetsNet;
        if (feeBps >= BPS_PRECISION) return 0; // impossible to mint (would require infinite gross)

        return Math.mulDiv(assetsNet, BPS_PRECISION, (BPS_PRECISION - feeBps), Math.Rounding.Ceil);
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
        if (receiver == address(0)) revert ZERO_ADDRESS();
        _validateController(controller);

        uint256 averageWithdrawPrice = strategy.getAverageWithdrawPrice(controller);
        if (averageWithdrawPrice == 0) revert INVALID_WITHDRAW_PRICE();

        uint256 maxWithdrawAmount = maxWithdraw(controller);
        if (assets > maxWithdrawAmount) revert INVALID_AMOUNT();

        // Calculate shares based on assets and average withdraw price
        shares = assets.mulDiv(PRECISION, averageWithdrawPrice, Math.Rounding.Ceil);

        uint256 escrowBalance = _asset.balanceOf(escrow);
        if (assets > escrowBalance) revert NOT_ENOUGH_ASSETS();

        // Take assets from strategy (7540 path)
        strategy.handleOperations7540(ISuperVaultStrategy.Operation.ClaimRedeem, controller, receiver, assets);

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
        if (receiver == address(0)) revert ZERO_ADDRESS();
        _validateController(controller);

        uint256 averageWithdrawPrice = strategy.getAverageWithdrawPrice(controller);
        if (averageWithdrawPrice == 0) revert INVALID_WITHDRAW_PRICE();

        // Calculate assets based on shares and average withdraw price
        assets = shares.mulDiv(averageWithdrawPrice, PRECISION, Math.Rounding.Floor);

        uint256 maxWithdrawAmount = maxWithdraw(controller);
        if (assets > maxWithdrawAmount) revert INVALID_AMOUNT();

        uint256 escrowBalance = _asset.balanceOf(escrow);
        if (assets > escrowBalance) revert NOT_ENOUGH_ASSETS();

        // Take assets from strategy (7540 path)
        strategy.handleOperations7540(ISuperVaultStrategy.Operation.ClaimRedeem, controller, receiver, assets);

        emit Withdraw(msg.sender, receiver, controller, assets, shares);
    }

    // @inheritdoc ISuperVault
    function burnShares(uint256 amount) external {
        if (msg.sender != address(strategy)) revert UNAUTHORIZED();
        _burn(escrow, amount);
    }

    // @inheritdoc ISuperVault
    function mintShares(address to, uint256 amount) external {
        if (msg.sender != address(strategy)) revert UNAUTHORIZED();
        _mint(to, amount);
    }

    /*//////////////////////////////////////////////////////////////
                            ERC165 INTERFACE
    //////////////////////////////////////////////////////////////*/
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == type(IERC7540Redeem).interfaceId || interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IERC7741).interfaceId || interfaceId == type(IERC4626).interfaceId
            || interfaceId == type(IERC7575).interfaceId || interfaceId == type(IERC7540Operator).interfaceId;
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Validates that the controller is the msg.sender or has been authorized by the controller
    /// @param controller The controller to validate
    function _validateController(address controller) internal view {
        if (controller != msg.sender && !isOperator[controller][msg.sender]) revert INVALID_CONTROLLER();
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

    /// @notice Checks if the vault is currently paused
    /// @dev This accesses the SuperVaultAggregator directly via the governor to determine pause status
    /// @return True if the vault is paused, false otherwise
    function _isPaused() internal view returns (bool) {
        address aggregatorAddress = superGovernor.getAddress(superGovernor.SUPER_VAULT_AGGREGATOR());
        return ISuperVaultAggregator(aggregatorAddress).isStrategyPaused(address(strategy));
    }

    function _isPPSStale() internal view returns (bool) {
        address aggregatorAddress = superGovernor.getAddress(superGovernor.SUPER_VAULT_AGGREGATOR());
        return ISuperVaultAggregator(aggregatorAddress).isPPSStale(address(strategy));
    }

    /// @dev Read management fee config (view-only for previews)
    function _getManagementFeeConfig() internal view returns (uint256 feeBps, address recipient) {
        ISuperVaultStrategy.FeeConfig memory cfg = strategy.getConfigInfo();
        return (cfg.managementFeeBps, cfg.recipient);
    }
}
