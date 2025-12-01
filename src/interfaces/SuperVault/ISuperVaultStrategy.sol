// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { ISuperHook, Execution } from "@superform-v2-core/src/interfaces/ISuperHook.sol";

/// @title ISuperVaultStrategy
/// @author Superform Labs
/// @notice Interface for SuperVault strategy implementation that manages yield sources and executes strategies
interface ISuperVaultStrategy {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error ZERO_LENGTH();
    error INVALID_HOOK();
    error ZERO_ADDRESS();
    error ACCESS_DENIED();
    error INVALID_AMOUNT();
    error OPERATION_FAILED();
    error INVALID_TIMESTAMP();
    error REQUEST_NOT_FOUND();
    error INVALID_ARRAY_LENGTH();
    error ACTION_TYPE_DISALLOWED();
    error YIELD_SOURCE_NOT_FOUND();
    error YIELD_SOURCE_ALREADY_EXISTS();
    error INVALID_PERFORMANCE_FEE_BPS();
    error MINIMUM_OUTPUT_AMOUNT_ASSETS_NOT_MET();
    error MANAGER_NOT_AUTHORIZED();
    error INVALID_PPS();
    error INVALID_VAULT();
    error INVALID_ASSET();
    error OPERATIONS_BLOCKED_BY_VETO();
    error HOOK_VALIDATION_FAILED();
    error STRATEGY_PAUSED();
    error NO_PROPOSAL();
    error INVALID_REDEEM_SLIPPAGE_BPS();
    error CANCELLATION_REDEEM_REQUEST_PENDING();
    error STALE_PPS();
    error PPS_EXPIRED();
    error INVALID_PPS_EXPIRY_THRESHOLD();
    error BOUNDS_EXCEEDED(uint256 minAllowed, uint256 maxAllowed, uint256 actual);
    error INSUFFICIENT_LIQUIDITY();
    error CONTROLLERS_NOT_SORTED_UNIQUE();
    error ZERO_SHARE_FULFILLMENT_DISALLOWED();
    error NOT_ENOUGH_FREE_ASSETS_FEE_SKIM();
    error SKIM_TIMELOCK_ACTIVE();

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event SuperGovernorSet(address indexed superGovernor);
    event Initialized(address indexed vault);
    event YieldSourceAdded(address indexed source, address indexed oracle);
    event YieldSourceOracleUpdated(address indexed source, address indexed oldOracle, address indexed newOracle);
    event YieldSourceRemoved(address indexed source);

    event VaultFeeConfigUpdated(uint256 performanceFeeBps, uint256 managementFeeBps, address indexed recipient);
    event VaultFeeConfigProposed(
        uint256 performanceFeeBps, uint256 managementFeeBps, address indexed recipient, uint256 effectiveTime
    );
    event HooksExecuted(address[] hooks);
    event RedeemRequestPlaced(address indexed controller, address indexed owner, uint256 shares);
    event RedeemRequestClaimed(address indexed controller, address indexed receiver, uint256 assets, uint256 shares);
    event RedeemRequestsFulfilled(address[] controllers, uint256 processedShares, uint256 currentPPS);
    event RedeemRequestCanceled(address indexed controller, uint256 shares);
    event RedeemCancelRequestPlaced(address indexed controller);
    event RedeemCancelRequestFulfilled(address indexed controller, uint256 shares);
    event HookExecuted(
        address indexed hook,
        address indexed prevHook,
        address indexed targetedYieldSource,
        bool usePrevHookAmount,
        bytes hookCalldata
    );

    event PPSUpdated(uint256 newPPS, uint256 calculationBlock);
    event FeeRecipientChanged(address indexed newRecipient);
    event ManagementFeePaid(address indexed controller, address indexed recipient, uint256 feeAssets, uint256 feeBps);
    event DepositHandled(address indexed controller, uint256 assets, uint256 shares);
    event RedeemClaimable(
        address indexed controller, uint256 assetsFulfilled, uint256 sharesFulfilled, uint256 averageWithdrawPrice
    );
    event RedeemSlippageSet(address indexed controller, uint16 slippageBps);

    event PPSExpirationProposed(uint256 currentProposedThreshold, uint256 ppsExpiration, uint256 effectiveTime);
    event PPSExpiryThresholdUpdated(uint256 ppsExpiration);
    event PPSExpiryThresholdProposalCanceled();

    /// @notice Emitted when the high-water mark PPS is updated after fee collection
    /// @param newHwmPps The new high-water mark PPS (post-fee)
    /// @param previousPps The PPS before fee collection
    /// @param profit The total profit above HWM (in assets)
    /// @param feeCollected The total fee collected (in assets)
    event HWMPPSUpdated(uint256 newHwmPps, uint256 previousPps, uint256 profit, uint256 feeCollected);

    /// @notice Emitted when the high-water mark PPS is reset
    /// @param newHwmPps The new high-water mark PPS (post-fee)
    event HighWaterMarkReset(uint256 newHwmPps);

    /// @notice Emitted when performance fees are skimmed
    /// @param totalFee The total fee collected (in assets)
    /// @param superformFee The fee collected for Superform (in assets)
    event PerformanceFeeSkimmed(uint256 totalFee, uint256 superformFee);

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct FeeConfig {
        uint256 performanceFeeBps; // On profit at fulfill time
        uint256 managementFeeBps; // Entry fee on deposit/mint (asset-side)
        address recipient; // Fee sink (entry + performance)
    }

    /// @notice Structure for hook execution arguments
    struct ExecuteArgs {
        /// @notice Array of hooks to execute
        address[] hooks;
        /// @notice Calldata for each hook (must match hooks array length)
        bytes[] hookCalldata;
        /// @notice Expected output amounts or output shares
        uint256[] expectedAssetsOrSharesOut;
        /// @notice Global Merkle proofs for hook validation (must match hooks array length)
        bytes32[][] globalProofs;
        /// @notice Strategy-specific Merkle proofs for hook validation (must match hooks array length)
        bytes32[][] strategyProofs;
    }

    struct YieldSource {
        address oracle; // Associated yield source oracle address
    }

    /// @notice Comprehensive information about a yield source including its address and configuration
    struct YieldSourceInfo {
        address sourceAddress; // Address of the yield source
        address oracle; // Associated yield source oracle address
    }

    /// @notice State specific to asynchronous redeem requests
    struct SuperVaultState {
        // Cancellation
        bool pendingCancelRedeemRequest;
        uint256 claimableCancelRedeemRequest;
        // Redeems
        uint256 pendingRedeemRequest; // Shares requested
        uint256 maxWithdraw; // Assets claimable after fulfillment
        uint256 averageRequestPPS; // Average PPS at the time of redeem request
        uint256 averageWithdrawPrice; // Average price for claimable assets
        uint16 redeemSlippageBps; // User-defined slippage tolerance in BPS for redeem fulfillment
    }

    struct ExecutionVars {
        bool success;
        address targetedYieldSource;
        uint256 outAmount;
        ISuperHook hookContract;
        Execution[] executions;
    }

    struct FulfillRedeemVars {
        uint256 totalRequestedShares;
        uint256 totalNetAssetsOut;
        uint256 currentPPS;
        uint256 strategyBalance;
    }

    /*//////////////////////////////////////////////////////////////
                                ENUMS
    //////////////////////////////////////////////////////////////*/
    enum Operation {
        RedeemRequest,
        CancelRedeemRequest,
        ClaimCancelRedeem,
        ClaimRedeem
    }

    /// @notice Action types for yield source management
    enum YieldSourceAction {
        Add, // 0: Add a new yield source
        UpdateOracle, // 1: Update an existing yield source's oracle
        Remove // 2: Remove a yield source
    }

    /// @notice Action types for PPS expiration threshold management
    enum PPSExpirationAction {
        Propose, // 0: Propose a new PPS expiration threshold
        Execute, // 1: Execute the proposed threshold update
        Cancel // 2: Cancel the pending threshold proposal
    }

    /*//////////////////////////////////////////////////////////////
                        CORE STRATEGY OPERATIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Initializes the strategy with required parameters
    /// @param vaultAddress Address of the associated SuperVault
    /// @param feeConfigData Fee configuration
    function initialize(address vaultAddress, FeeConfig memory feeConfigData) external;

    /// @notice Execute a 4626 deposit by processing assets.
    /// @param controller The controller address
    /// @param assetsGross The amount of gross assets user has to deposit
    /// @return sharesNet The amount of net shares to mint
    function handleOperations4626Deposit(address controller, uint256 assetsGross) external returns (uint256 sharesNet);

    /// @notice Execute a 4626 mint by processing shares.
    /// @param controller The controller address
    /// @param sharesNet The amount of shares to mint
    /// @param assetsGross The amount of gross assets user has to deposit
    /// @param assetsNet The amount of net assets that strategy will receive
    function handleOperations4626Mint(
        address controller,
        uint256 sharesNet,
        uint256 assetsGross,
        uint256 assetsNet
    )
        external;

    /// @notice Quotes the amount of assets that will be received for a given amount of shares.
    /// @param shares The amount of shares to mint
    /// @return assetsGross The amount of gross assets that will be received
    /// @return assetsNet The amount of net assets that will be received
    function quoteMintAssetsGross(uint256 shares) external view returns (uint256 assetsGross, uint256 assetsNet);

    /// @notice Execute async redeem requests (redeem, cancel, claim).
    /// @param op The operation type (RedeemRequest, CancelRedeem, ClaimRedeem)
    /// @param controller The controller address
    /// @param receiver The receiver address
    /// @param amount The amount of assets or shares
    function handleOperations7540(Operation op, address controller, address receiver, uint256 amount) external;

    /*//////////////////////////////////////////////////////////////
                MANAGER EXTERNAL ACCESS FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Execute hooks for general strategy management (rebalancing, etc.).
    /// @param args Execution arguments containing hooks, calldata, proofs, expectations.
    function executeHooks(ExecuteArgs calldata args) external payable;

    /// @notice Fulfills pending cancel redeem requests by making shares claimable
    /// @dev Processes all controllers with pending cancellation flags
    /// @dev Can only be called by authorized managers
    /// @param controllers Array of controller addresses with pending cancel requests
    function fulfillCancelRedeemRequests(address[] memory controllers) external;

    /// @notice Fulfills pending redeem requests with exact total assets per controller (pre-fee).
    /// @dev PRE: Off-chain sort/unique controllers. Call executeHooks(sum(totalAssetsOut)) first.
    /// @dev Social: totalAssetsOut[i] = theoreticalGross[i] (full). Selective: totalAssetsOut[i] < theoreticalGross[i].
    /// @dev NOTE: totalAssetsOut includes fees - actual net amount received is calculated internally after fee
    /// deduction. @param controllers Ordered/unique controllers with pending requests.
    /// @param totalAssetsOut Total PRE-FEE assets available for each controller[i] (from executeHooks).
    function fulfillRedeemRequests(address[] calldata controllers, uint256[] calldata totalAssetsOut) external;

    /// @notice Skim performance fees based on per-share High Water Mark (PPS-based)
    /// @dev Can be called by any manager when vault PPS has grown above HWM PPS
    /// @dev Uses PPS growth to calculate profit: (currentPPS - hwmPPS) * totalSupply / PRECISION
    /// @dev HWM is only updated during this function, not during deposits/redemptions
    function skimPerformanceFee() external;

    /*//////////////////////////////////////////////////////////////
                        YIELD SOURCE MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @notice Manage a single yield source: add, update oracle, or remove
    /// @param source Address of the yield source
    /// @param oracle Address of the oracle (used for adding/updating, ignored for removal)
    /// @param actionType Type of action (see YieldSourceAction enum)
    function manageYieldSource(address source, address oracle, YieldSourceAction actionType) external;

    /// @notice Batch manage multiple yield sources in a single transaction
    /// @param sources Array of yield source addresses
    /// @param oracles Array of oracle addresses (used for adding/updating, ignored for removal)
    /// @param actionTypes Array of action types (see YieldSourceAction enum)
    function manageYieldSources(
        address[] calldata sources,
        address[] calldata oracles,
        YieldSourceAction[] calldata actionTypes
    )
        external;

    /// @notice Change the fee recipient when the primary manager is changed
    /// @param newRecipient New fee recipient
    function changeFeeRecipient(address newRecipient) external;

    /// @notice Propose or execute a hook root update
    /// @notice Propose changes to vault-specific fee configuration
    /// @param performanceFeeBps New performance fee in basis points
    /// @param managementFeeBps New management fee in basis points
    /// @param recipient New fee recipient
    /// @dev IMPORTANT: Before executing the proposed update (via executeVaultFeeConfigUpdate),
    ///      manager should call skimPerformanceFee() to collect performance fees on existing profits
    ///      under the current fee structure to avoid losing profit or incorrect fee calculations.
    function proposeVaultFeeConfigUpdate(
        uint256 performanceFeeBps,
        uint256 managementFeeBps,
        address recipient
    )
        external;

    /// @notice Execute the proposed vault fee configuration update after timelock
    /// @dev IMPORTANT: Manager should call skimPerformanceFee() before executing this update
    ///      to collect performance fees on existing profits under the current fee structure.
    ///      Otherwise, profit earned under the old fee percentage will be lost or incorrectly calculated.
    /// @dev This function will reset the High Water Mark (vaultHwmPps) to the current PPS value
    ///      to avoid incorrect fee calculations with the new fee structure.
    function executeVaultFeeConfigUpdate() external;

    /// @notice Reset the high-water mark PPS to the current PPS
    /// @dev This function is only callable by Aggregator
    /// @dev This function will reset the High Water Mark (vaultHwmPps) to the current PPS value
    /// @param newHwmPps The new high-water mark PPS value
    function resetHighWaterMark(uint256 newHwmPps) external;

    /// @notice Manage PPS expiry threshold
    /// @param action Type of action (see PPSExpirationAction enum)
    /// @param ppsExpiration The new PPS expiry threshold
    function managePPSExpiration(PPSExpirationAction action, uint256 ppsExpiration) external;

    /*//////////////////////////////////////////////////////////////
                        ACCOUNTING MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                        USER OPERATIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Set the slippage tolerance for all future redeem request fulfillments, until reset using this function
    /// @param slippageBps Slippage tolerance in basis points (e.g., 50 = 0.5%)
    function setRedeemSlippage(uint16 slippageBps) external;

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the vault info
    function getVaultInfo() external view returns (address vault, address asset, uint8 vaultDecimals);

    /// @notice Get the fee configurations
    function getConfigInfo() external view returns (FeeConfig memory feeConfig);

    /// @notice Returns the currently stored PPS value.
    function getStoredPPS() external view returns (uint256);

    /// @notice Get a yield source's configuration
    function getYieldSource(address source) external view returns (YieldSource memory);

    /// @notice Get all yield sources with their information
    /// @return Array of YieldSourceInfo structs
    function getYieldSourcesList() external view returns (YieldSourceInfo[] memory);

    /// @notice Get all yield source addresses
    /// @return Array of yield source addresses
    function getYieldSources() external view returns (address[] memory);

    /// @notice Get the count of yield sources
    /// @return Number of yield sources
    function getYieldSourcesCount() external view returns (uint256);

    /// @notice Check if a yield source exists
    /// @param source Address of the yield source
    /// @return True if the yield source exists
    function containsYieldSource(address source) external view returns (bool);

    /// @notice Get the average withdraw price for a controller
    /// @param controller The controller address
    /// @return averageWithdrawPrice The average withdraw price
    function getAverageWithdrawPrice(address controller) external view returns (uint256 averageWithdrawPrice);

    /// @notice Get the super vault state for a controller
    /// @param controller The controller address
    /// @return state The super vault state
    function getSuperVaultState(address controller) external view returns (SuperVaultState memory state);

    /// @notice Get the pending redeem request amount (shares) for a controller
    /// @param controller The controller address
    /// @return pendingShares The amount of shares pending redemption
    function pendingRedeemRequest(address controller) external view returns (uint256 pendingShares);

    /// @notice Get the pending cancellation for a redeem request for a controller
    /// @param controller The controller address
    /// @return isPending True if the redeem request is pending cancellation
    function pendingCancelRedeemRequest(address controller) external view returns (bool isPending);

    /// @notice Get the claimable cancel redeem request amount (shares) for a controller
    /// @param controller The controller address
    /// @return claimableShares The amount of shares claimable
    function claimableCancelRedeemRequest(address controller) external view returns (uint256 claimableShares);

    /// @notice Get the claimable withdraw amount (assets) for a controller
    /// @param controller The controller address
    /// @return claimableAssets The amount of assets claimable
    function claimableWithdraw(address controller) external view returns (uint256 claimableAssets);

    /// @notice Preview exact redeem fulfillment for off-chain calculation
    /// @param controller The controller address to preview
    /// @return shares Pending redeem shares
    /// @return theoreticalAssets Theoretical assets at current PPS
    /// @return minAssets Minimum acceptable assets (slippage floor)
    function previewExactRedeem(address controller)
        external
        view
        returns (uint256 shares, uint256 theoreticalAssets, uint256 minAssets);

    /// @notice Batch preview exact redeem fulfillment for multiple controllers
    /// @dev Efficiently batches multiple previewExactRedeem calls to reduce RPC overhead
    /// @param controllers Array of controller addresses to preview
    /// @return totalTheoAssets Total theoretical assets across all controllers
    /// @return individualAssets Array of theoretical assets per controller
    function previewExactRedeemBatch(address[] calldata controllers)
        external
        view
        returns (uint256 totalTheoAssets, uint256[] memory individualAssets);

    /// @notice Get the current unrealized profit above the High Water Mark
    /// @return profit Current profit above High Water Mark (in assets), 0 if no profit
    /// @dev Calculates based on PPS growth: (currentPPS - hwmPPS) * totalSupply / PRECISION
    /// @dev Returns 0 if totalSupply is 0 or currentPPS <= hwmPPS
    function vaultUnrealizedProfit() external view returns (uint256);
}
