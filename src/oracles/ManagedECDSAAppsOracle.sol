// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

// Superform
import { ECDSAPPSOracle } from "./ECDSAPPSOracle.sol";
import { IECDSAPPSOracle } from "../interfaces/oracles/IECDSAPPSOracle.sol";
import { ISuperVaultAggregator } from "../interfaces/SuperVault/ISuperVaultAggregator.sol";
import { IManagedECDSAAppsOracle } from "../interfaces/oracles/IManagedECDSAAppsOracle.sol";

/// @title ManagedECDSAAppsOracle
/// @author Superform Labs
/// @notice Extends ECDSAPPSOracle with a managed attestation path for portfolio manager NAV updates.
/// @dev Replaces ECDSAPPSOracle as the system-wide _activePPSOracle. Has two dispatch paths:
///      1. ECDSA path (inherited): N-of-M validator signatures → aggregator.forwardPPS (automated strategies)
///      2. Managed path (new): single manager call → aggregator.forwardPPS (managed strategies)
///      Routing guard: managed strategies CANNOT use ECDSA path; ECDSA strategies CANNOT use managed path.
contract ManagedECDSAAppsOracle is ECDSAPPSOracle, IManagedECDSAAppsOracle {
    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/
    bytes32 private constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 private constant ORACLE_MANAGER_ROLE = keccak256("ORACLE_MANAGER_ROLE");
    bytes32 private constant SUPER_VAULT_AGGREGATOR = keccak256("SUPER_VAULT_AGGREGATOR");

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IManagedECDSAAppsOracle
    mapping(address strategy => bool managed) public isManagedStrategy;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @notice Initializes the ManagedECDSAAppsOracle contract
    /// @param superGovernor_ Address of the SuperGovernor contract
    /// @param name_ EIP-712 domain name (e.g., "SuperformOraclePPS")
    /// @param version_ EIP-712 domain version (e.g., "1")
    constructor(
        address superGovernor_,
        string memory name_,
        string memory version_
    )
        ECDSAPPSOracle(superGovernor_, name_, version_)
    { }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IManagedECDSAAppsOracle
    function setManagedStrategy(address strategy, bool managed) external {
        if (!SUPER_GOVERNOR.hasRole(GOVERNOR_ROLE, msg.sender)) revert UNAUTHORIZED();
        isManagedStrategy[strategy] = managed;
        emit ManagedStrategySet(strategy, managed);
    }

    /// @inheritdoc IManagedECDSAAppsOracle
    function updatePPSManaged(address strategy, uint256 pps) external {
        if (!isManagedStrategy[strategy]) revert NOT_MANAGED_STRATEGY();

        address aggregator = SUPER_GOVERNOR.getAddress(SUPER_VAULT_AGGREGATOR);
        address mainManager = ISuperVaultAggregator(aggregator).getMainManager(strategy);

        bool isManager = (msg.sender == mainManager);
        bool isOracleManager = SUPER_GOVERNOR.hasRole(ORACLE_MANAGER_ROLE, msg.sender);
        if (!isManager && !isOracleManager) revert UNAUTHORIZED();

        address[] memory strategies = new address[](1);
        strategies[0] = strategy;
        uint256[] memory ppss = new uint256[](1);
        ppss[0] = pps;
        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = block.timestamp;

        ISuperVaultAggregator(aggregator).forwardPPS(
            ISuperVaultAggregator.ForwardPPSArgs({
                strategies: strategies,
                ppss: ppss,
                timestamps: timestamps,
                updateAuthority: msg.sender
            })
        );

        emit ManagedPPSUpdated(strategy, pps, msg.sender);
    }

    /// @notice Override ECDSA path to block managed strategies from being updated via ECDSA signatures
    /// @dev Iterates args.strategies and reverts if any strategy is registered as managed, then delegates to parent
    function updatePPS(IECDSAPPSOracle.UpdatePPSArgs calldata args) public override(ECDSAPPSOracle, IECDSAPPSOracle) {
        uint256 len = args.strategies.length;
        for (uint256 i; i < len; ++i) {
            if (isManagedStrategy[args.strategies[i]]) revert MANAGED_STRATEGY_IN_ECDSA_PATH();
        }
        super.updatePPS(args);
    }
}
