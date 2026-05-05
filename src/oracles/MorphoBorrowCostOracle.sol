// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

// Morpho
import { Id } from "@superform-v2-core/src/vendor/morpho/IMorpho.sol";
import { SharesMathLib } from "@superform-v2-core/src/vendor/morpho/SharesMathLib.sol";

// Superform
import { AbstractMorphoOracle } from "./AbstractMorphoOracle.sol";
import { AbstractYieldSourceOracle } from "@superform-v2-core/src/accounting/oracles/AbstractYieldSourceOracle.sol";

/// @title MorphoBorrowCostOracle
/// @author Superform Labs
/// @notice Oracle for Morpho Blue borrow (debt) positions
/// @dev Reads borrow shares and market totals directly from Morpho's singleton contract.
///      PPS increases over time as interest accrues on debt — representing growing borrow cost.
///      All asset conversions round UP (conservative debt estimation — borrower owes at least this much).
///      Interest is accrued in-memory using Morpho's IRM for up-to-date values.
contract MorphoBorrowCostOracle is AbstractMorphoOracle {
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
    /// @dev Rounds UP — debt PPS increases over time, conservative estimation.
    ///      Uses interest-adjusted market data for up-to-date values.
    function getPricePerShare(address yieldSourceId) public view override returns (uint256) {
        Id marketId = _getMarketId(yieldSourceId);
        uint256 loanDecimals = yieldSourceDecimals[yieldSourceId];

        (,, uint256 totalBorrowAssets, uint256 totalBorrowShares) = _expectedMarketBalances(marketId);

        return (10 ** loanDecimals).toAssetsUp(totalBorrowAssets, totalBorrowShares);
    }

    /// @inheritdoc AbstractYieldSourceOracle
    /// @dev Rounds UP — you owe at least this much.
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
        (,, uint256 totalBorrowAssets, uint256 totalBorrowShares) = _expectedMarketBalances(marketId);

        return sharesIn.toAssetsUp(totalBorrowAssets, totalBorrowShares);
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
        (,, uint256 totalBorrowAssets, uint256 totalBorrowShares) = _expectedMarketBalances(marketId);

        return assetsIn.toSharesDown(totalBorrowAssets, totalBorrowShares);
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
        (,, uint256 totalBorrowAssets, uint256 totalBorrowShares) = _expectedMarketBalances(marketId);

        return assetsIn.toSharesUp(totalBorrowAssets, totalBorrowShares);
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
        (, uint128 borrowShares,) = MORPHO.position(marketId, ownerOfShares);
        return borrowShares;
    }

    /// @inheritdoc AbstractYieldSourceOracle
    /// @dev Rounds UP — debt in asset terms (conservative).
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
        (, uint128 borrowShares,) = MORPHO.position(marketId, ownerOfShares);
        if (borrowShares == 0) return 0;

        (,, uint256 totalBorrowAssets, uint256 totalBorrowShares) = _expectedMarketBalances(marketId);

        return uint256(borrowShares).toAssetsUp(totalBorrowAssets, totalBorrowShares);
    }

    /// @inheritdoc AbstractYieldSourceOracle
    /// @dev Returns interest-adjusted total borrow assets
    function getTVL(address yieldSourceId) public view override returns (uint256) {
        Id marketId = _getMarketId(yieldSourceId);
        (,, uint256 totalBorrowAssets,) = _expectedMarketBalances(marketId);
        return totalBorrowAssets;
    }
}
