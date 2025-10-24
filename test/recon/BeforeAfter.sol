// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {MockERC20} from "@recon/MockERC20.sol";

import {ISuperVaultStrategy} from "src/interfaces/SuperVault/ISuperVaultStrategy.sol";

import {Setup} from "./Setup.sol";

enum OpType {
    DEFAULT,
    ADD,
    REMOVE,
    FULFILL,
    REQUEST,
    TRANSFER,
    CANCEL
}

// ghost variables for tracking state variable values before and after function calls
abstract contract BeforeAfter is Setup {
    struct Vars {
        mapping(address user => uint256 pendingAsAssets) pendingUserAssets;
        mapping(address user => uint256 claimableAsAssets) claimableUserAssets;
        mapping(address user => ISuperVaultStrategy.SuperVaultState) state;
        mapping(address user => uint256 shares) superVaultShares;
        uint256 oraclePPS;
        uint256 naivePPS;
        uint256 summedTotalShares;
        uint256 summedAccumulatorShares;
        uint256 summedAccumulatorCostBasis;
        uint256 summedTotalAssets;
        uint256 strategyAssetBalance;
        uint256 summedPendingRedeem;
    }

    Vars internal _before;
    Vars internal _after;
    OpType internal _currentOp;

    modifier updateGhosts() {
        _currentOp = OpType.DEFAULT;
        __before();
        _;
        __after();
    }

    modifier updateGhostsWithOpType(OpType op) {
        _currentOp = op;
        __before();
        _;
        __after();
    }

    function __before() internal {
        (
            _before.summedAccumulatorShares,
            _before.summedAccumulatorCostBasis
        ) = _sumSuperVaultValues();
        _before.naivePPS = _calculateNaivePPS();
        _before.summedTotalShares = _sumTotalShares();
        _before.summedTotalAssets = _sumStrategyAssets();
        _before.summedPendingRedeem = _sumRequestedRedemptions();

        _before.pendingUserAssets[_getActor()] = _getPendingAsAssets();
        _before.claimableUserAssets[_getActor()] = _getClaimableAsAssets();
        _before.state[_getActor()] = superVaultStrategy.getSuperVaultState(
            _getActor()
        );
        _before.superVaultShares[_getActor()] = superVault.balanceOf(
            _getActor()
        );

        _before.strategyAssetBalance = MockERC20(superVault.asset()).balanceOf(
            address(superVaultStrategy)
        );
        _before.oraclePPS = superVaultAggregator.getPPS(
            address(superVaultStrategy)
        );
    }

    function __after() internal {
        (
            _after.summedAccumulatorShares,
            _after.summedAccumulatorCostBasis
        ) = _sumSuperVaultValues();
        _after.naivePPS = _calculateNaivePPS();
        _after.summedTotalShares = _sumTotalShares();
        _after.summedTotalAssets = _sumStrategyAssets();
        _after.summedPendingRedeem = _sumRequestedRedemptions();

        _after.pendingUserAssets[_getActor()] = _getPendingAsAssets();
        _after.claimableUserAssets[_getActor()] = _getClaimableAsAssets();
        _after.state[_getActor()] = superVaultStrategy.getSuperVaultState(
            _getActor()
        );
        _after.superVaultShares[_getActor()] = superVault.balanceOf(
            _getActor()
        );

        _after.strategyAssetBalance = MockERC20(superVault.asset()).balanceOf(
            address(superVaultStrategy)
        );
        _after.oraclePPS = superVaultAggregator.getPPS(
            address(superVaultStrategy)
        );
    }

    // Helpers

    /// @dev total shares in the system is the sum of shares in the escrow and held by all users
    function _sumTotalShares() internal returns (uint256) {
        address[] memory actors = _getActors();
        uint256 totalShares;

        totalShares += superVault.balanceOf(address(superVaultEscrow));
        for (uint256 i; i < actors.length; i++) {
            totalShares += superVault.balanceOf(actors[i]);
        }

        return totalShares;
    }

    /// @notice Calculates the naive price per share by summing all assets across strategy and yield sources
    /// @dev inspired by the share price calculation from BaseSuperVaultTest::_updateSuperVaultPPS
    /// @return naivePPS The calculated price per share (scaled by 1e18)
    function _calculateNaivePPS() internal returns (uint256 naivePPS) {
        // Get total supply of SuperVault shares
        uint256 totalSupply = superVault.totalSupply();

        // If no shares exist, PPS is 0
        if (totalSupply == 0) {
            return 0;
        }

        // Calculate total assets across all locations
        uint256 totalAssets = _sumStrategyAssets();

        // Calculate naive PPS: (totalAssets * PRECISION) / totalSupply
        // Using 1e18 as precision to match the system's PPS_DECIMALS
        naivePPS = (totalAssets * superVault.PRECISION()) / totalSupply;

        return naivePPS;
    }

    function _sumStrategyAssets() public view returns (uint256) {
        // Get the underlying asset
        address asset = superVault.asset();

        uint256 totalAssets;
        // 1. Assets held directly in SuperVaultStrategy
        totalAssets += IERC20(asset).balanceOf(address(superVaultStrategy));

        // 2. Loop through all yield sources and sum underlying asset balances
        address[] memory yieldSources = _getYieldSources();
        for (uint256 i = 0; i < yieldSources.length; i++) {
            if (yieldSources[i] != address(0)) {
                // Get the underlying asset balance held in each yield source
                totalAssets += IERC20(asset).balanceOf(yieldSources[i]);
            }
        }

        return totalAssets;
    }

    function _sumSuperVaultValues()
        internal
        view
        returns (uint256 sumAccumulatorShares, uint256 sumAccumulatorCostBasis)
    {
        address[] memory actors = _getActors();

        for (uint256 i; i < actors.length; i++) {
            sumAccumulatorShares += superVaultStrategy
                .getSuperVaultState(actors[i])
                .accumulatorShares;
            sumAccumulatorCostBasis += superVaultStrategy
                .getSuperVaultState(actors[i])
                .accumulatorCostBasis;
        }
    }

    function _sumRequestedRedemptions() internal returns (uint256) {
        address[] memory actors = _getActors();
        uint256 totalRequested;
        for (uint256 i; i < actors.length; i++) {
            totalRequested += superVault.pendingRedeemRequest(0, actors[i]);
        }

        return totalRequested;
    }

    function _getPendingAsAssets() internal returns (uint256) {
        uint256 pendingRedemptions = superVault.pendingRedeemRequest(
            0,
            _getActor()
        );
        uint256 pendingRedemptionsAsAssets = superVault.convertToAssets(
            pendingRedemptions
        );

        return pendingRedemptionsAsAssets;
    }

    function _getClaimableAsAssets() internal returns (uint256) {
        uint256 claimableRedemptions = superVault.claimableRedeemRequest(
            0,
            _getActor()
        );
        uint256 claimableRedemptionsAsAssets = superVault.convertToAssets(
            claimableRedemptions
        );

        return claimableRedemptionsAsAssets;
    }
}
