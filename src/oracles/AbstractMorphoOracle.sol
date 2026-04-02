// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

// external
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

// Morpho
import { Id, IMorphoStaticTyping, Market, MarketParams } from "@superform-v2-core/src/vendor/morpho/IMorpho.sol";
import { IIrm } from "@superform-v2-core/src/vendor/morpho/IIrm.sol";
import { MarketParamsLib } from "@superform-v2-core/src/vendor/morpho/MarketParamsLib.sol";
import { MathLib } from "@superform-v2-core/src/vendor/morpho/MathLib.sol";
import { SharesMathLib } from "@superform-v2-core/src/vendor/morpho/SharesMathLib.sol";

// Superform
import { AbstractYieldSourceOracle } from "@superform-v2-core/src/accounting/oracles/AbstractYieldSourceOracle.sol";

/// @title AbstractMorphoOracle
/// @author Superform Labs
/// @notice Shared base for Morpho Blue oracle wrappers (lend and borrow)
/// @dev Handles market registration, decimals caching, and interest-adjusted market data.
///      Concrete implementations only need to define the direction-specific conversion functions.
///      Interest is accrued in-memory via the market's IRM for up-to-date values without
///      requiring a prior call to MORPHO.accrueInterest(). If the IRM view call fails,
///      raw (stale) values are returned as a fallback.
///      Multiple yieldSourceIds may intentionally point to the same Morpho market;
///      callers must handle deduplication when aggregating TVL across yieldSourceIds.
abstract contract AbstractMorphoOracle is AbstractYieldSourceOracle, AccessControl {
    using MarketParamsLib for MarketParams;
    using SharesMathLib for uint256;
    using MathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Role that can register and unregister markets
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    /// @notice Immutable address of the Morpho Blue singleton contract
    IMorphoStaticTyping public immutable MORPHO;

    /// @notice Mapping from yield source identifier to Morpho market Id
    /// @dev Morpho Blue is a singleton — markets are identified by MarketParams hashed to Id (bytes32),
    ///      not by unique addresses. Since IYieldSourceOracle takes address (20 bytes), we need this mapping.
    mapping(address yieldSourceId => Id marketId) public marketIds;

    /// @notice Cached loan token decimals per yield source, set at registration time
    /// @dev Avoids repeated external calls to IERC20Metadata.decimals() on every read
    mapping(address yieldSourceId => uint8) public yieldSourceDecimals;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a market is registered
    event MarketRegistered(address indexed yieldSourceId, Id indexed marketId);

    /// @notice Emitted when a market is unregistered
    event MarketUnregistered(address indexed yieldSourceId, Id indexed marketId);

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when a zero address is provided
    error ZERO_ADDRESS();

    /// @notice Thrown when querying an unregistered market
    error MARKET_NOT_REGISTERED();

    /// @notice Thrown when trying to register a market that doesn't exist on Morpho
    error MARKET_DOES_NOT_EXIST();

    /// @notice Thrown when trying to register a yield source id that is already registered
    error MARKET_ALREADY_REGISTERED();

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Initialize the oracle
    /// @param morpho_ Address of the Morpho Blue singleton contract
    /// @param superLedgerConfiguration_ Address of the SuperLedgerConfiguration contract
    /// @param admin_ Address that receives DEFAULT_ADMIN_ROLE and MANAGER_ROLE
    constructor(
        address morpho_,
        address superLedgerConfiguration_,
        address admin_
    )
        AbstractYieldSourceOracle(superLedgerConfiguration_)
    {
        if (morpho_ == address(0) || superLedgerConfiguration_ == address(0) || admin_ == address(0)) {
            revert ZERO_ADDRESS();
        }
        MORPHO = IMorphoStaticTyping(morpho_);

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(MANAGER_ROLE, admin_);
    }

    /*//////////////////////////////////////////////////////////////
                        MARKET REGISTRATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Register a Morpho market with a yield source identifier
    /// @dev Only callable by MANAGER_ROLE. Once registered, a yieldSourceId cannot be overwritten
    ///      (must unregister first). Multiple yieldSourceIds may map to the same market.
    /// @param yieldSourceId The address to use as the yield source identifier
    /// @param params The Morpho market parameters
    function registerMarket(address yieldSourceId, MarketParams calldata params) external onlyRole(MANAGER_ROLE) {
        if (yieldSourceId == address(0)) revert ZERO_ADDRESS();
        if (Id.unwrap(marketIds[yieldSourceId]) != bytes32(0)) revert MARKET_ALREADY_REGISTERED();

        Id marketId = MarketParamsLib.id(params);

        // Validate market exists on Morpho by checking lastUpdate > 0
        (,,,, uint128 lastUpdate,) = MORPHO.market(marketId);
        if (lastUpdate == 0) revert MARKET_DOES_NOT_EXIST();

        marketIds[yieldSourceId] = marketId;
        yieldSourceDecimals[yieldSourceId] = IERC20Metadata(params.loanToken).decimals();

        emit MarketRegistered(yieldSourceId, marketId);
    }

    /// @notice Unregister a previously registered market
    /// @dev Only callable by MANAGER_ROLE.
    /// @param yieldSourceId The yield source identifier to unregister
    function unregisterMarket(address yieldSourceId) external onlyRole(MANAGER_ROLE) {
        Id marketId = marketIds[yieldSourceId];
        if (Id.unwrap(marketId) == bytes32(0)) revert MARKET_NOT_REGISTERED();

        marketIds[yieldSourceId] = Id.wrap(bytes32(0));
        delete yieldSourceDecimals[yieldSourceId];

        emit MarketUnregistered(yieldSourceId, marketId);
    }

    /*//////////////////////////////////////////////////////////////
                    SHARED ORACLE IMPLEMENTATIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc AbstractYieldSourceOracle
    /// @dev Returns cached decimals set at registration time
    function decimals(address yieldSourceId) external view override returns (uint8) {
        _getMarketId(yieldSourceId);
        return yieldSourceDecimals[yieldSourceId];
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get and validate the market Id for a yield source identifier
    /// @param yieldSourceId The yield source identifier
    /// @return marketId The Morpho market Id
    function _getMarketId(address yieldSourceId) internal view returns (Id marketId) {
        marketId = marketIds[yieldSourceId];
        if (Id.unwrap(marketId) == bytes32(0)) revert MARKET_NOT_REGISTERED();
    }

    /// @notice Get interest-adjusted market balances
    /// @dev Replicates Morpho's _accrueInterest logic in a view context using IIrm.borrowRateView().
    ///      If the IRM call fails (e.g., IRM not deployed or incompatible), falls back to raw values.
    ///      Uses the same MathLib.wTaylorCompounded 3-term Taylor expansion as Morpho Blue core.
    /// @param marketId The Morpho market Id
    /// @return totalSupplyAssets Interest-adjusted total supply assets
    /// @return totalSupplyShares Interest-adjusted total supply shares (includes fee recipient accrual)
    /// @return totalBorrowAssets Interest-adjusted total borrow assets
    /// @return totalBorrowShares Total borrow shares (unchanged by interest accrual)
    function _expectedMarketBalances(Id marketId)
        internal
        view
        returns (uint256 totalSupplyAssets, uint256 totalSupplyShares, uint256 totalBorrowAssets, uint256 totalBorrowShares)
    {
        uint256 elapsed;
        uint128 fee;

        {
            uint128 _totalSupplyAssets;
            uint128 _totalSupplyShares;
            uint128 _totalBorrowAssets;
            uint128 _totalBorrowShares;
            uint128 lastUpdate;

            (_totalSupplyAssets, _totalSupplyShares, _totalBorrowAssets, _totalBorrowShares, lastUpdate, fee) =
                MORPHO.market(marketId);

            totalSupplyAssets = _totalSupplyAssets;
            totalSupplyShares = _totalSupplyShares;
            totalBorrowAssets = _totalBorrowAssets;
            totalBorrowShares = _totalBorrowShares;
            elapsed = block.timestamp - lastUpdate;
        }

        // No elapsed time or no borrows — return raw values
        if (elapsed == 0 || totalBorrowAssets == 0) {
            return (totalSupplyAssets, totalSupplyShares, totalBorrowAssets, totalBorrowShares);
        }

        MarketParams memory params = _getMarketParams(marketId);

        // Safe: values originate as uint128 from MORPHO.market() and are unmodified;
        // lastUpdate fits in uint128 for billions of years
        Market memory mkt = Market({
            // forge-lint: disable-next-line(unsafe-typecast)
            totalSupplyAssets: uint128(totalSupplyAssets),
            // forge-lint: disable-next-line(unsafe-typecast)
            totalSupplyShares: uint128(totalSupplyShares),
            // forge-lint: disable-next-line(unsafe-typecast)
            totalBorrowAssets: uint128(totalBorrowAssets),
            // forge-lint: disable-next-line(unsafe-typecast)
            totalBorrowShares: uint128(totalBorrowShares),
            // forge-lint: disable-next-line(unsafe-typecast)
            lastUpdate: uint128(block.timestamp - elapsed),
            fee: fee
        });

        uint256 interest = _accrueInterestView(params, mkt, totalBorrowAssets, elapsed);

        if (interest > 0) {
            totalBorrowAssets += interest;
            totalSupplyAssets += interest;

            // Accrue fee shares if applicable (uses post-interest totalSupplyAssets)
            if (fee != 0) {
                uint256 feeAmount = interest.wMulDown(fee);
                totalSupplyShares += feeAmount.toSharesDown(totalSupplyAssets, totalSupplyShares);
            }
        }
    }

    /// @notice Fetch MarketParams from Morpho for a given market Id
    /// @dev Separated to avoid stack-too-deep in callers
    function _getMarketParams(Id marketId) private view returns (MarketParams memory params) {
        (address loanToken, address collateralToken, address oracleAddr, address irm, uint256 lltv) =
            MORPHO.idToMarketParams(marketId);
        params = MarketParams({
            loanToken: loanToken,
            collateralToken: collateralToken,
            oracle: oracleAddr,
            irm: irm,
            lltv: lltv
        });
    }

    /// @notice Compute accrued interest via the market's IRM in a view context
    /// @dev Calls borrowRateView on the IRM. Returns 0 if the IRM call fails.
    function _accrueInterestView(
        MarketParams memory params,
        Market memory mkt,
        uint256 totalBorrowAssets_,
        uint256 elapsed_
    )
        private
        view
        returns (uint256)
    {
        try IIrm(params.irm).borrowRateView(params, mkt) returns (uint256 borrowRate) {
            return totalBorrowAssets_.wMulDown(borrowRate.wTaylorCompounded(elapsed_));
        } catch {
            return 0;
        }
    }
}
