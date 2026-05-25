// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Id, IMorphoStaticTyping, MarketParams } from "@superform-v2-core/src/vendor/morpho/IMorpho.sol";
import { MarketParamsLib } from "@superform-v2-core/src/vendor/morpho/MarketParamsLib.sol";

/// @notice Mock ERC20 token for testing Morpho oracles
contract MockMorphoERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
    }
}

/// @notice Mock Morpho singleton for testing oracles
/// @dev Only implements the view functions needed by the oracles
contract MockMorpho {
    struct MockMarketData {
        uint128 totalSupplyAssets;
        uint128 totalSupplyShares;
        uint128 totalBorrowAssets;
        uint128 totalBorrowShares;
        uint128 lastUpdate;
        uint128 fee;
    }

    struct MockPositionData {
        uint256 supplyShares;
        uint128 borrowShares;
        uint128 collateral;
    }

    /// @notice Market data by Id
    mapping(bytes32 => MockMarketData) public markets;

    /// @notice Position data by (Id, user)
    mapping(bytes32 => mapping(address => MockPositionData)) public positions;

    /// @notice Market params by Id
    mapping(bytes32 => MarketParams) public marketParamsStorage;

    /// @notice Set market data for a given Id
    function setMarket(
        Id id,
        uint128 totalSupplyAssets,
        uint128 totalSupplyShares,
        uint128 totalBorrowAssets,
        uint128 totalBorrowShares,
        uint128 lastUpdate,
        uint128 fee
    )
        external
    {
        markets[Id.unwrap(id)] = MockMarketData({
            totalSupplyAssets: totalSupplyAssets,
            totalSupplyShares: totalSupplyShares,
            totalBorrowAssets: totalBorrowAssets,
            totalBorrowShares: totalBorrowShares,
            lastUpdate: lastUpdate,
            fee: fee
        });
    }

    /// @notice Set position data for a given (Id, user)
    function setPosition(
        Id id,
        address user,
        uint256 supplyShares,
        uint128 borrowShares,
        uint128 collateral
    )
        external
    {
        positions[Id.unwrap(id)][user] =
            MockPositionData({ supplyShares: supplyShares, borrowShares: borrowShares, collateral: collateral });
    }

    /// @notice Set market params for a given Id
    function setMarketParams(Id id, MarketParams memory params) external {
        marketParamsStorage[Id.unwrap(id)] = params;
    }

    /// @notice IMorphoStaticTyping.market
    function market(Id id)
        external
        view
        returns (
            uint128 totalSupplyAssets,
            uint128 totalSupplyShares,
            uint128 totalBorrowAssets,
            uint128 totalBorrowShares,
            uint128 lastUpdate,
            uint128 fee
        )
    {
        MockMarketData memory m = markets[Id.unwrap(id)];
        return (m.totalSupplyAssets, m.totalSupplyShares, m.totalBorrowAssets, m.totalBorrowShares, m.lastUpdate, m.fee);
    }

    /// @notice IMorphoStaticTyping.position
    function position(
        Id id,
        address user
    )
        external
        view
        returns (uint256 supplyShares, uint128 borrowShares, uint128 collateral)
    {
        MockPositionData memory p = positions[Id.unwrap(id)][user];
        return (p.supplyShares, p.borrowShares, p.collateral);
    }

    /// @notice IMorphoStaticTyping.idToMarketParams
    function idToMarketParams(Id id)
        external
        view
        returns (address loanToken, address collateralToken, address oracle, address irm, uint256 lltv)
    {
        MarketParams memory params = marketParamsStorage[Id.unwrap(id)];
        return (params.loanToken, params.collateralToken, params.oracle, params.irm, params.lltv);
    }
}
