// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { IECDSAPPSOracle } from "./IECDSAPPSOracle.sol";

/// @title IManagedECDSAAppsOracle
/// @author Superform Labs
/// @notice Interface for the ManagedECDSAAppsOracle contract
interface IManagedECDSAAppsOracle is IECDSAPPSOracle {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @notice Thrown when the strategy is not registered as a managed strategy
    error NOT_MANAGED_STRATEGY();
    /// @notice Thrown when the caller is not authorized to attest NAV for the strategy
    error UNAUTHORIZED();
    /// @notice Thrown when a managed strategy is used in the ECDSA path
    error MANAGED_STRATEGY_IN_ECDSA_PATH();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when a managed strategy's PPS is updated
    /// @param strategy Address of the strategy
    /// @param pps New price-per-share value
    /// @param updatedBy Address that submitted the update
    event ManagedPPSUpdated(address indexed strategy, uint256 pps, address indexed updatedBy);

    /// @notice Emitted when a strategy's managed status is changed
    /// @param strategy Address of the strategy
    /// @param managed New managed status
    event ManagedStrategySet(address indexed strategy, bool managed);

    /*//////////////////////////////////////////////////////////////
                              VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns whether a strategy is registered as a managed strategy
    /// @param strategy Address of the strategy
    /// @return managed True if the strategy is managed
    function isManagedStrategy(address strategy) external view returns (bool managed);

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Register or unregister a strategy as managed
    /// @dev Only callable by GOVERNOR_ROLE holders
    /// @param strategy Address of the strategy to register/unregister
    /// @param managed True to register, false to unregister
    function setManagedStrategy(address strategy, bool managed) external;

    /// @notice Manager attests NAV for a managed strategy directly (no ECDSA signatures required)
    /// @dev Caller must be the strategy's mainManager (from aggregator) or hold ORACLE_MANAGER_ROLE
    /// @param strategy The SV strategy address registered in isManagedStrategy
    /// @param pps The price-per-share value in PRECISION units
    function updatePPSManaged(address strategy, uint256 pps) external;
}
