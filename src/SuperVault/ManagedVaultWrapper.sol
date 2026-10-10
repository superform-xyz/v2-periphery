// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

// External
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// OpenZeppelin Upgradeable
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";

// Superform interfaces
import { ISuperVaultAggregator } from "../interfaces/SuperVault/ISuperVaultAggregator.sol";
import { IManagedVaultWrapper } from "../interfaces/SuperVault/IManagedVaultWrapper.sol";
import { IERC7540Vault, IERC7540Deposit, IERC7540Redeem, IERC7540Operator } from
    "../vendor/standards/ERC7540/IERC7540Vault.sol";
import { IERC7741 } from "../vendor/standards/ERC7741/IERC7741.sol";

/// @title ManagedVaultWrapper
/// @author Superform Labs
/// @notice Fully async ERC-7540 vault wrapping SuperVault shares with manager-attested NAV.
/// @dev Investors requestDeposit/requestRedeem asynchronously. The manager fulfills batches after
///      attesting NAV via ManagedECDSAAppsOracle.updatePPSManaged(svStrategy, pps).
///
///      Architecture:
///      - Asset:      any ERC-20 (e.g. USDC)
///      - Underlying: SuperVault (ERC-20) shares held in this contract
///      - NAV:        svShares × aggregator.getPPS(svStrategy) / PRECISION
///                    (no storedPPS in wrapper; manager sets PPS via oracle → aggregator.forwardPPS)
///
///      First-depositor protection: 1000 dead shares burned to 0xdead in initialize().
contract ManagedVaultWrapper is
    Initializable,
    ERC20Upgradeable,
    ReentrancyGuardUpgradeable,
    EIP712Upgradeable,
    IERC7540Vault,
    IManagedVaultWrapper
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/
    uint256 private constant REQUEST_ID = 0;

    /// @notice Dead shares burned at initialization to prevent first-depositor inflation attack
    uint256 public constant DEAD_SHARES = 1000;

    /// @dev EIP-712 typehash for authorizeOperator signatures (ERC-7741)
    bytes32 public constant AUTHORIZE_OPERATOR_TYPEHASH = keccak256(
        "AuthorizeOperator(address controller,address operator,bool approved,bytes32 nonce,uint256 deadline)"
    );

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IManagedVaultWrapper
    address public asset;

    /// @inheritdoc IManagedVaultWrapper
    address public svVault;

    /// @inheritdoc IManagedVaultWrapper
    address public svStrategy;

    /// @inheritdoc IManagedVaultWrapper
    address public aggregator;

    /// @inheritdoc IManagedVaultWrapper
    address public mainManager;

    /// @inheritdoc IManagedVaultWrapper
    bool public isPaused;

    /// @inheritdoc IManagedVaultWrapper
    bool public isGated;

    /// @notice Asset precision (10^assetDecimals)
    uint256 public PRECISION;

    // ------- ERC-7540 deposit state -------
    /// @notice Pending deposit assets per controller (transferred but not yet fulfilled)
    mapping(address controller => uint256 assets) private _pendingDepositRequest;

    /// @notice Wrapper shares minted and awaiting investor claim
    mapping(address controller => uint256 shares) public claimableDepositShares;

    // ------- ERC-7540 redeem state -------
    /// @notice Pending redeem shares per controller (locked in this contract, not yet fulfilled)
    mapping(address controller => uint256 shares) private _pendingRedeemRequest;

    /// @notice Shares moved to claimable state after manager fulfills redeem (ready to burn on claim)
    mapping(address controller => uint256 shares) private _claimableRedeemShares;

    /// @notice Assets owed to each controller after redeem is fulfilled
    mapping(address controller => uint256 assets) public claimableRedeemAssets;

    /// @notice Sum of all assets currently in pendingDepositRequest (for pre-deposit NAV)
    uint256 public totalPendingDeposits;

    /// @inheritdoc IManagedVaultWrapper
    mapping(address investor => bool allowed) public allowlist;

    // ------- ERC-7741 operator state -------
    /// @inheritdoc IERC7540Operator
    mapping(address owner => mapping(address operator => bool)) public isOperator;

    /// @notice One-time nonces for authorizeOperator signatures (ERC-7741)
    mapping(address controller => mapping(bytes32 nonce => bool used)) private _authorizations;

    /*//////////////////////////////////////////////////////////////
                            EVENTS (ERC-4626 compatible)
    //////////////////////////////////////////////////////////////*/
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(
        address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @dev Prevents the implementation contract from being initialized
    constructor() {
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IManagedVaultWrapper
    function initialize(
        address asset_,
        string memory name_,
        string memory symbol_,
        address svVault_,
        address svStrategy_,
        address mainManager_,
        bool isGated_,
        address aggregator_
    )
        external
        initializer
    {
        if (asset_ == address(0) || svVault_ == address(0) || svStrategy_ == address(0)) revert ZERO_ADDRESS();
        if (mainManager_ == address(0) || aggregator_ == address(0)) revert ZERO_ADDRESS();

        __ERC20_init(name_, symbol_);
        __ReentrancyGuard_init();
        __EIP712_init(name_, "1");

        asset = asset_;
        svVault = svVault_;
        svStrategy = svStrategy_;
        mainManager = mainManager_;
        isGated = isGated_;
        aggregator = aggregator_;
        PRECISION = 10 ** IERC20Metadata(asset_).decimals();

        // First-depositor protection: burn dead shares so the initial exchange rate
        // is set by the first real depositor, not by the factory.
        _mint(address(0xdead), DEAD_SHARES);

        emit Initialized(asset_, svVault_, svStrategy_, mainManager_);
    }

    /*//////////////////////////////////////////////////////////////
                           ERC-20 OVERRIDE
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns decimals equal to the underlying asset (standard ERC-4626 pattern)
    function decimals() public view override returns (uint8) {
        return IERC20Metadata(asset).decimals();
    }

    /*//////////////////////////////////////////////////////////////
                              VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IManagedVaultWrapper
    function totalAssets() public view returns (uint256) {
        // NAV from SV shares (valued at manager-attested PPS from aggregator)
        uint256 svShares = IERC20(svVault).balanceOf(address(this));
        uint256 svPPS = ISuperVaultAggregator(aggregator).getPPS(svStrategy);
        // Raw asset balance: includes assets from claimable redeems + any un-deployed deposits
        uint256 rawAssets = IERC20(asset).balanceOf(address(this));
        return (svShares * svPPS) / PRECISION + rawAssets;
    }

    /// @inheritdoc IManagedVaultWrapper
    function isPPSStale() public view returns (bool) {
        uint256 lastUpdate = ISuperVaultAggregator(aggregator).getLastUpdateTimestamp(svStrategy);
        uint256 maxStaleness = ISuperVaultAggregator(aggregator).getMaxStaleness(svStrategy);
        return block.timestamp > lastUpdate + maxStaleness;
    }

    /*//////////////////////////////////////////////////////////////
                          ERC-7540 DEPOSIT PATH
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IERC7540Deposit
    /// @notice Submits an async deposit request. Assets are held in this contract until fulfilled.
    function requestDeposit(
        uint256 assets_,
        address controller,
        address owner
    )
        external
        nonReentrant
        returns (uint256 requestId)
    {
        if (assets_ == 0) revert ZERO_AMOUNT();
        if (controller == address(0) || owner == address(0)) revert ZERO_ADDRESS();
        if (isPaused) revert PAUSED();
        if (isGated && !allowlist[controller]) revert NOT_ALLOWLISTED();
        _requireAuthorized(owner);

        // Effects before interactions (CEI)
        _pendingDepositRequest[controller] += assets_;
        totalPendingDeposits += assets_;

        // Pull assets from owner
        IERC20(asset).safeTransferFrom(owner, address(this), assets_);

        emit DepositRequest(controller, owner, REQUEST_ID, msg.sender, assets_);
        return REQUEST_ID;
    }

    /// @inheritdoc IERC7540Deposit
    function pendingDepositRequest(uint256, address controller)
        external
        view
        override(IERC7540Deposit, IManagedVaultWrapper)
        returns (uint256)
    {
        return _pendingDepositRequest[controller];
    }

    /// @inheritdoc IERC7540Deposit
    function claimableDepositRequest(uint256, address controller) external view returns (uint256) {
        return claimableDepositShares[controller];
    }

    /// @notice Manager fulfills pending deposit requests by minting wrapper shares
    /// @dev Manager must have already deployed the pending USDC into the SV strategy.
    ///      Share price uses pre-deposit NAV (excludes pending deposits that haven't been deployed):
    ///        priorAssets = totalAssets() - totalPendingDeposits
    ///        shares      = pendingAssets × priorSupply / priorAssets
    ///      Minted shares are held in this contract until investors claim.
    /// @param controllers Array of controller addresses to fulfill
    function fulfillDepositRequests(address[] calldata controllers) external nonReentrant {
        if (msg.sender != mainManager) revert UNAUTHORIZED();
        if (isPaused) revert PAUSED();
        if (isPPSStale()) revert PPS_STALE();

        uint256 len = controllers.length;
        if (len == 0) revert ZERO_AMOUNT();

        // Pre-deposit NAV: subtract pending deposits that are still sitting as raw assets
        uint256 priorAssets = totalAssets() - totalPendingDeposits;
        // Effective supply excludes dead shares (which have no economic backing)
        uint256 priorSupply = totalSupply() - DEAD_SHARES;

        uint256 totalSharesMinted;

        for (uint256 i; i < len; ++i) {
            address controller = controllers[i];
            uint256 pendingAssets = _pendingDepositRequest[controller];
            if (pendingAssets == 0) revert NO_PENDING_DEPOSIT();

            uint256 shares;
            if (priorAssets == 0 || priorSupply == 0) {
                // First real deposit: issue shares 1:1 with asset units
                shares = pendingAssets;
            } else {
                shares = (pendingAssets * priorSupply) / priorAssets;
            }

            // CEI: state before minting
            _pendingDepositRequest[controller] = 0;
            totalPendingDeposits -= pendingAssets;
            claimableDepositShares[controller] += shares;
            totalSharesMinted += shares;

            emit DepositClaimable(controller, REQUEST_ID, pendingAssets, shares);
        }

        if (totalSharesMinted > 0) {
            _mint(address(this), totalSharesMinted);
        }

        emit DepositRequestsFulfilled(len, totalSharesMinted);
    }

    /// @inheritdoc IERC7540Deposit
    /// @notice ERC-7540 claim: transfers claimable deposit shares to receiver
    function deposit(uint256, address receiver, address controller) external nonReentrant returns (uint256 shares) {
        if (receiver == address(0) || controller == address(0)) revert ZERO_ADDRESS();
        _requireAuthorized(controller);
        return _claimDeposit(controller, receiver);
    }

    /// @inheritdoc IERC7540Deposit
    /// @notice Not supported — this vault is async-only
    function mint(uint256, address, address) external pure returns (uint256) {
        revert UNAUTHORIZED();
    }

    /// @inheritdoc IManagedVaultWrapper
    function claimDeposit(address controller, address receiver) external nonReentrant returns (uint256 shares) {
        if (receiver == address(0) || controller == address(0)) revert ZERO_ADDRESS();
        _requireAuthorized(controller);
        return _claimDeposit(controller, receiver);
    }

    /*//////////////////////////////////////////////////////////////
                          ERC-7540 REDEEM PATH
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IERC7540Redeem
    /// @notice Submits an async redeem request. Shares are locked until manager fulfills.
    function requestRedeem(
        uint256 shares,
        address controller,
        address owner
    )
        external
        nonReentrant
        returns (uint256 requestId)
    {
        if (shares == 0) revert ZERO_AMOUNT();
        if (controller == address(0) || owner == address(0)) revert ZERO_ADDRESS();
        if (isPaused) revert PAUSED();
        _requireAuthorized(owner);

        if (balanceOf(owner) < shares) revert INSUFFICIENT_ASSETS();

        // CEI: state before transfer
        _pendingRedeemRequest[controller] += shares;

        // Lock shares in this contract (burned when manager calls fulfillRedeemRequests)
        _transfer(owner, address(this), shares);

        emit RedeemRequest(controller, owner, REQUEST_ID, msg.sender, shares);
        return REQUEST_ID;
    }

    /// @inheritdoc IERC7540Redeem
    function pendingRedeemRequest(uint256, address controller) external view returns (uint256) {
        return _pendingRedeemRequest[controller];
    }

    /// @inheritdoc IERC7540Redeem
    /// @notice Returns the claimable shares for the controller (non-zero after manager fulfills)
    function claimableRedeemRequest(uint256, address controller) external view returns (uint256) {
        return _claimableRedeemShares[controller];
    }

    /// @notice Manager fulfills pending redeem requests
    /// @dev Manager must have already redeemed SV shares and transferred the resulting assets here.
    ///      Shares move from pending → claimable and will be burned when investor calls claimRedeem.
    /// @param controllers Array of controller addresses to fulfill
    /// @param assetsOut Array of asset amounts assigned to each controller
    function fulfillRedeemRequests(
        address[] calldata controllers,
        uint256[] calldata assetsOut
    )
        external
        nonReentrant
    {
        if (msg.sender != mainManager) revert UNAUTHORIZED();
        if (controllers.length != assetsOut.length) revert ARRAY_LENGTH_MISMATCH();

        uint256 len = controllers.length;
        if (len == 0) revert ZERO_AMOUNT();

        uint256 totalSharesMovedToClaimable;
        uint256 totalAssetsOut;

        for (uint256 i; i < len; ++i) {
            address controller = controllers[i];
            uint256 pendingShares = _pendingRedeemRequest[controller];
            if (pendingShares == 0) revert NO_PENDING_REDEEM();

            uint256 assets_ = assetsOut[i];

            // CEI: state updates before any external effects
            _pendingRedeemRequest[controller] = 0;
            _claimableRedeemShares[controller] += pendingShares;
            claimableRedeemAssets[controller] += assets_;
            totalSharesMovedToClaimable += pendingShares;
            totalAssetsOut += assets_;

            emit RedeemClaimable(controller, REQUEST_ID, assets_, pendingShares);
        }

        emit RedeemRequestsFulfilled(len, totalSharesMovedToClaimable, totalAssetsOut);
    }

    /// @inheritdoc IManagedVaultWrapper
    function claimRedeem(address controller, address receiver) external nonReentrant returns (uint256 assets_) {
        if (receiver == address(0) || controller == address(0)) revert ZERO_ADDRESS();
        _requireAuthorized(controller);
        return _claimRedeem(controller, receiver);
    }

    /// @notice ERC-7540 withdraw — delegates to claimRedeem
    function redeem(uint256, address receiver, address controller) external nonReentrant returns (uint256 assets_) {
        if (receiver == address(0) || controller == address(0)) revert ZERO_ADDRESS();
        _requireAuthorized(controller);
        return _claimRedeem(controller, receiver);
    }

    /*//////////////////////////////////////////////////////////////
                         ERC-7741 / ERC-7540 OPERATOR
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IERC7540Operator
    function setOperator(address operator, bool approved) external returns (bool) {
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
        if (_authorizations[controller][nonce]) revert NONCE_USED();

        _authorizations[controller][nonce] = true;

        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(AUTHORIZE_OPERATOR_TYPEHASH, controller, operator, approved, nonce, deadline))
        );
        address signer = ECDSA.recover(digest, signature);
        if (signer != controller) revert INVALID_SIGNATURE();

        isOperator[controller][operator] = approved;
        emit OperatorSet(controller, operator, approved);
        return true;
    }

    /// @inheritdoc IERC7741
    function invalidateNonce(bytes32 nonce) external {
        _authorizations[msg.sender][nonce] = true;
    }

    /// @inheritdoc IERC7741
    function authorizations(address controller, bytes32 nonce) external view returns (bool) {
        return _authorizations[controller][nonce];
    }

    /// @inheritdoc IERC7741
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /*//////////////////////////////////////////////////////////////
                          MANAGEMENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IManagedVaultWrapper
    function setAllowlist(address[] calldata investors, bool[] calldata allowed) external {
        if (msg.sender != mainManager) revert UNAUTHORIZED();
        if (investors.length != allowed.length) revert ARRAY_LENGTH_MISMATCH();
        for (uint256 i; i < investors.length; ++i) {
            allowlist[investors[i]] = allowed[i];
            emit AllowlistSet(investors[i], allowed[i]);
        }
    }

    /// @inheritdoc IManagedVaultWrapper
    function setPaused(bool paused) external {
        if (msg.sender != mainManager) revert UNAUTHORIZED();
        isPaused = paused;
        emit PauseSet(paused);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Reverts if msg.sender is not controller and not an approved operator
    function _requireAuthorized(address controller) internal view {
        if (msg.sender != controller && !isOperator[controller][msg.sender]) {
            revert INVALID_OPERATOR();
        }
    }

    /// @notice Claims claimable deposit shares for a controller
    function _claimDeposit(address controller, address receiver) internal returns (uint256 shares) {
        shares = claimableDepositShares[controller];
        if (shares == 0) revert NO_CLAIMABLE_SHARES();

        claimableDepositShares[controller] = 0;
        _transfer(address(this), receiver, shares);

        emit Deposit(msg.sender, receiver, 0, shares);
    }

    /// @notice Claims fulfilled redeem assets for a controller (burns their locked shares)
    function _claimRedeem(address controller, address receiver) internal returns (uint256 assets_) {
        uint256 shares = _claimableRedeemShares[controller];
        assets_ = claimableRedeemAssets[controller];
        if (assets_ == 0) revert NO_CLAIMABLE_ASSETS();

        // CEI: zero state before external transfer
        _claimableRedeemShares[controller] = 0;
        claimableRedeemAssets[controller] = 0;

        // Burn the locked shares that were set aside during requestRedeem
        if (shares > 0) {
            _burn(address(this), shares);
        }

        IERC20(asset).safeTransfer(receiver, assets_);

        emit Withdraw(msg.sender, receiver, controller, assets_, shares);
    }
}
