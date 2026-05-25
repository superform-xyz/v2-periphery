// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

// Morpho
import { Id } from "@superform-v2-core/src/vendor/morpho/IMorpho.sol";
import { SharesMathLib } from "@superform-v2-core/src/vendor/morpho/SharesMathLib.sol";

// Superform
import { AbstractMorphoOracle } from "./AbstractMorphoOracle.sol";
import { AbstractYieldSourceOracle } from "@superform-v2-core/src/accounting/oracles/AbstractYieldSourceOracle.sol";

/// @title MorphoLendYieldSourceOracle
/// @author Superform Labs
/// @notice Oracle for Morpho Blue lending (supply) positions
/// @dev Reads supply shares and market totals directly from Morpho's singleton contract.
///      PPS increases over time as interest accrues on the supply side.
///      All asset conversions round DOWN (favor protocol).
///      Interest is accrued in-memory using Morpho's IRM for up-to-date values.
contract MorphoLendYieldSourceOracle is AbstractMorphoOracle {
    using SharesMathLib for uint256;

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
        AbstractMorphoOracle(morpho_, superLedgerConfiguration_, admin_)
    { }

    /*//////////////////////////////////////////////////////////////
                    IYIELDSOURCEORACLE IMPLEMENTATION
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc AbstractYieldSourceOracle
    /// @dev Rounds DOWN — supply PPS is conservative for protocol accounting (favors protocol).
    ///      Uses interest-adjusted market data for up-to-date values.
    function getPricePerShare(address yieldSourceId) public view override returns (uint256) {
        Id marketId = _getMarketId(yieldSourceId);
        uint256 loanDecimals = yieldSourceDecimals[yieldSourceId];

        (uint256 totalSupplyAssets, uint256 totalSupplyShares,,) = _expectedMarketBalances(marketId);

        return (10 ** loanDecimals).toAssetsDown(totalSupplyAssets, totalSupplyShares);
    }

    /// @inheritdoc AbstractYieldSourceOracle
    /// @dev Rounds DOWN — protocol-favorable asset output for lender withdrawals.
    ///      Uses interest-adjusted market data for up-to-date values.
    function getAssetOutput(
        address yieldSourceId,
        address,
        uint256 sharesIn
    )
        public
        view
        override
        returns (uint256)
    {
        Id marketId = _getMarketId(yieldSourceId);
        (uint256 totalSupplyAssets, uint256 totalSupplyShares,,) = _expectedMarketBalances(marketId);

        return sharesIn.toAssetsDown(totalSupplyAssets, totalSupplyShares);
    }

    /// @inheritdoc AbstractYieldSourceOracle
    function getShareOutput(
        address yieldSourceId,
        address,
        uint256 assetsIn
    )
        external
        view
        override
        returns (uint256)
    {
        Id marketId = _getMarketId(yieldSourceId);
        (uint256 totalSupplyAssets, uint256 totalSupplyShares,,) = _expectedMarketBalances(marketId);

        return assetsIn.toSharesDown(totalSupplyAssets, totalSupplyShares);
    }

    /// @inheritdoc AbstractYieldSourceOracle
    function getWithdrawalShareOutput(
        address yieldSourceId,
        address,
        uint256 assetsIn
    )
        external
        view
        override
        returns (uint256)
    {
        Id marketId = _getMarketId(yieldSourceId);
        (uint256 totalSupplyAssets, uint256 totalSupplyShares,,) = _expectedMarketBalances(marketId);

        return assetsIn.toSharesUp(totalSupplyAssets, totalSupplyShares);
    }

    /// @inheritdoc AbstractYieldSourceOracle
    function getBalanceOfOwner(
        address yieldSourceId,
        address ownerOfShares
    )
        public
        view
        override
        returns (uint256)
    {
        Id marketId = _getMarketId(yieldSourceId);
        (uint256 supplyShares,,) = MORPHO.position(marketId, ownerOfShares);
        return supplyShares;
    }

    /// @inheritdoc AbstractYieldSourceOracle
    /// @dev Rounds DOWN — protocol-favorable TVL for supply positions.
    ///      Uses interest-adjusted market data for up-to-date values.
    function getTVLByOwnerOfShares(
        address yieldSourceId,
        address ownerOfShares
    )
        public
        view
        override
        returns (uint256)
    {
        Id marketId = _getMarketId(yieldSourceId);
        (uint256 supplyShares,,) = MORPHO.position(marketId, ownerOfShares);
        if (supplyShares == 0) return 0;

        (uint256 totalSupplyAssets, uint256 totalSupplyShares,,) = _expectedMarketBalances(marketId);

        return supplyShares.toAssetsDown(totalSupplyAssets, totalSupplyShares);
    }

    /// @inheritdoc AbstractYieldSourceOracle
    /// @dev Returns interest-adjusted total supply assets
    function getTVL(address yieldSourceId) public view override returns (uint256) {
        Id marketId = _getMarketId(yieldSourceId);
        (uint256 totalSupplyAssets,,,) = _expectedMarketBalances(marketId);
        return totalSupplyAssets;
    }
}
