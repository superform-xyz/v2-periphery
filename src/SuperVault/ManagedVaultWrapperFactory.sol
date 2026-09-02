// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

// External
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

// Superform
import { ISuperGovernor } from "../interfaces/ISuperGovernor.sol";
import { IManagedECDSAAppsOracle } from "../interfaces/oracles/IManagedECDSAAppsOracle.sol";
import { IManagedVaultWrapper } from "../interfaces/SuperVault/IManagedVaultWrapper.sol";

/// @title ManagedVaultWrapperFactory
/// @author Superform Labs
/// @notice Minimal-proxy factory for creating ManagedVaultWrapper instances.
/// @dev Only GOVERNOR_ROLE holders can create new wrappers.
///      Each wrapper is cloned from `wrapperImpl` and initialized inline.
///      The factory also registers the underlying svStrategy as a managed strategy
///      in the ManagedECDSAAppsOracle so the manager can attest NAV via updatePPSManaged.
contract ManagedVaultWrapperFactory {
    using Clones for address;

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    error UNAUTHORIZED();
    error ZERO_ADDRESS();
    error ZERO_AMOUNT();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when a new ManagedVaultWrapper is deployed
    /// @param wrapper Address of the newly deployed wrapper
    /// @param svVault Address of the underlying SuperVault (ERC-4626)
    /// @param svStrategy Address of the underlying SuperVaultStrategy (aggregator key)
    /// @param mainManager Address of the manager assigned to this wrapper
    /// @param asset Address of the wrapper's underlying asset
    event WrapperCreated(
        address indexed wrapper,
        address indexed svVault,
        address indexed svStrategy,
        address mainManager,
        address asset
    );

    /*//////////////////////////////////////////////////////////////
                                 STRUCTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Parameters for creating a new ManagedVaultWrapper
    /// @param asset Underlying asset token (e.g. USDC)
    /// @param name ERC-20 name for the wrapper shares
    /// @param symbol ERC-20 symbol for the wrapper shares
    /// @param mainManager Address of the portfolio manager
    /// @param isGated If true, only allowlisted investors can requestDeposit
    /// @param svVault Address of the existing SuperVault (ERC-4626 that wrapper will invest into)
    /// @param svStrategy Address of the SuperVaultStrategy (registered in aggregator for PPS)
    struct WrapperCreationParams {
        address asset;
        string name;
        string symbol;
        address mainManager;
        bool isGated;
        address svVault;
        address svStrategy;
    }

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/
    bytes32 private constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 private constant SUPER_VAULT_AGGREGATOR = keccak256("SUPER_VAULT_AGGREGATOR");

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/
    /// @notice The SuperGovernor contract for access control
    ISuperGovernor public immutable SUPER_GOVERNOR;

    /// @notice The oracle contract for registering managed strategies
    IManagedECDSAAppsOracle public immutable ORACLE;

    /// @notice The ManagedVaultWrapper implementation address for cloning
    address public immutable WRAPPER_IMPL;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @param superGovernor_ Address of the SuperGovernor contract
    /// @param oracle_ Address of the ManagedECDSAAppsOracle
    /// @param wrapperImpl_ Address of the ManagedVaultWrapper implementation to clone
    constructor(address superGovernor_, address oracle_, address wrapperImpl_) {
        if (superGovernor_ == address(0) || oracle_ == address(0) || wrapperImpl_ == address(0)) {
            revert ZERO_ADDRESS();
        }
        SUPER_GOVERNOR = ISuperGovernor(superGovernor_);
        ORACLE = IManagedECDSAAppsOracle(oracle_);
        WRAPPER_IMPL = wrapperImpl_;
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Deploys a new ManagedVaultWrapper and registers the svStrategy as managed
    /// @dev Only callable by GOVERNOR_ROLE holders
    /// @param params Wrapper creation parameters
    /// @return wrapper Address of the deployed wrapper
    function createWrapper(WrapperCreationParams calldata params) external returns (address wrapper) {
        if (!SUPER_GOVERNOR.hasRole(GOVERNOR_ROLE, msg.sender)) revert UNAUTHORIZED();
        if (params.asset == address(0) || params.svVault == address(0) || params.svStrategy == address(0)) {
            revert ZERO_ADDRESS();
        }
        if (params.mainManager == address(0)) revert ZERO_ADDRESS();

        // Get the aggregator address from superGovernor for passing to wrapper
        address aggregator = SUPER_GOVERNOR.getAddress(SUPER_VAULT_AGGREGATOR);

        // Deploy a minimal proxy clone of the wrapper implementation
        wrapper = WRAPPER_IMPL.clone();

        // Initialize the clone
        IManagedVaultWrapper(wrapper).initialize(
            params.asset, params.name, params.symbol, params.svVault, params.svStrategy, params.mainManager, params.isGated, aggregator
        );

        // Register the svStrategy (NOT the wrapper) as managed in the oracle
        // This allows the manager to call updatePPSManaged(svStrategy, pps)
        ORACLE.setManagedStrategy(params.svStrategy, true);

        emit WrapperCreated(wrapper, params.svVault, params.svStrategy, params.mainManager, params.asset);
    }
}
