// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// testing
import { BaseTest } from "../../BaseTest.t.sol";
import { TotalAssetHelper } from "./TotalAssetHelper.sol";

// external
import { console2 } from "forge-std/console2.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import { IERC20Metadata } from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import { MessageHashUtils } from "openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

import { ModuleKitHelpers, AccountInstance, UserOpData } from "modulekit/ModuleKit.sol";

// centrifuge mocks
import { IRoot } from "@superform-v2-core/test/mocks/centrifuge/IRoot.sol";
import { ITranche } from "@superform-v2-core/test/mocks/centrifuge/ITranch.sol";
import { RestrictionManagerLike } from "@superform-v2-core/test/mocks/centrifuge/IRestrictionManagerLike.sol";
import { IInvestmentManager } from "@superform-v2-core/test/mocks/centrifuge/IInvestmentManager.sol";
import { IPoolManager } from "@superform-v2-core/test/mocks/centrifuge/IPoolManager.sol";
import { IERC7540 } from "@superform-v2-core/src/vendor/vaults/7540/IERC7540.sol";

// superform
import { IYieldSourceOracle } from "@superform-v2-core/src/interfaces/accounting/IYieldSourceOracle.sol";
import { IStandardizedYield } from "@superform-v2-core/src/vendor/pendle/IStandardizedYield.sol";
import { SuperVault } from "../../../src/SuperVault/SuperVault.sol";
import { SuperVaultStrategy } from "../../../src/SuperVault/SuperVaultStrategy.sol";
import { SuperVaultEscrow } from "../../../src/SuperVault/SuperVaultEscrow.sol";
import { SuperVaultAggregator } from "../../../src/SuperVault/SuperVaultAggregator.sol";
import { SuperGovernor } from "../../../src/SuperGovernor.sol";
import { FeeType } from "../../../src/interfaces/ISuperGovernor.sol";
import { ISuperVaultStrategy } from "../../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { ISuperExecutor } from "@superform-v2-core/src/interfaces/ISuperExecutor.sol";
import { ISuperVaultAggregator } from "../../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { IECDSAPPSOracle } from "../../../src/interfaces/oracles/IECDSAPPSOracle.sol";
import { MerkleReader } from "../../utils/merkle/helper/MerkleReader.sol";
import { ISuperHookInspector } from "@superform-v2-core/src/interfaces/ISuperHook.sol";
import { SuperVaultExecuteHooksHook } from "../../mocks/SuperVaultExecuteHooksHook.sol";
import { SuperVaultManageYieldSourceHook } from "../../mocks/SuperVaultManageYieldSourceHook.sol";
import { HooksHelpers } from "../../utils/hooks/HooksHelpers.sol";
import { ISuperOracle } from "../../../src/interfaces/oracles/ISuperOracle.sol";
import { MockChainlinkOracle } from "../../mocks/MockChainlinkOracle.sol";
import { MockUp } from "../../mocks/MockUp.sol";
import { MockFeedWithRealData } from "../../mocks/MockFeedWithRealData.sol";
import { MockERC20 } from "../../mocks/MockERC20.sol";
import { ISuperLedgerConfiguration } from "@superform-v2-core/src/interfaces/accounting/ISuperLedgerConfiguration.sol";
import { ERC7540YieldSourceOracle } from "@superform-v2-core/src/accounting/oracles/ERC7540YieldSourceOracle.sol";
import { ERC4626YieldSourceOracle } from "@superform-v2-core/src/accounting/oracles/ERC4626YieldSourceOracle.sol";
import { ISuperLedger } from "@superform-v2-core/src/interfaces/accounting/ISuperLedger.sol";


contract BaseSuperVaultTest is MerkleReader, BaseTest, HooksHelpers {
    using MessageHashUtils for bytes32;
    using ModuleKitHelpers for *;
    using Math for uint256;

    address public accountEth;
    AccountInstance public instanceOnEth;
    AccountInstance[] accInstances;

    ISuperExecutor public superExecutorOnEth;

    // Config contracts
    ISuperLedger public superLedgerETH;
    ERC7540YieldSourceOracle public oracle;
    ERC4626YieldSourceOracle public oracle4626;
    ISuperLedgerConfiguration public configSuperLedger;

    // Core contracts
    SuperVault public vault;
    SuperVaultEscrow public escrow;
    SuperVaultAggregator public aggregator;
    SuperVaultStrategy public strategy;
    SuperGovernor public superGovernor;
    IECDSAPPSOracle public ecdsappsOracle;
    ISuperOracle public superOracle;
    MockERC20 public mockUSD;

    address internal upToken;
    address public oracleEthToUsd;
    address public oracleUsdToUp;
    address public oracleGasToEth;
    MockFeedWithRealData public mockFeedWithRealDataEthToUsd;
    MockFeedWithRealData public mockFeedWithRealDataGasToEth;

    // Helper contracts
    TotalAssetHelper public totalAssetHelper;

    // Tokens and yield sources
    IERC20Metadata public asset;
    IERC20Metadata public asset5115;
    IERC4626 public fluidVault;
    IERC4626 public aaveVault;
    address public pendleEthenaAddress;
    IStandardizedYield public pendleEthena;


    // Constants
    uint256 constant LARGE_DEPOSIT = 100_000e6; // 100k USDC
    uint256 private constant BPS_PRECISION = 10_000;
    uint256 constant ONE_HUNDRED_PERCENT = 10_000;

    // Update state tracking
    struct SuperVaultState {
        uint256 accumulatorShares;
        uint256 accumulatorCostBasis;
    }

    // Track state for each user
    mapping(address user => SuperVaultState) private superVaultStates;

    // Validator private keys
    uint256 public validator1PrivateKey;
    uint256 public validator2PrivateKey;
    uint256 public validator3PrivateKey;

    // Centrifuge
    uint64 public poolId;
    uint128 public assetId;
    bytes16 public trancheId;

    address public rootManager;
    IRoot public rootCentrifuge;
    IPoolManager public poolManager;

    IERC7540 public centrifugeVault;
    address public yieldSource7540AddressETH_USDC;

    IInvestmentManager public investmentManager;
    RestrictionManagerLike public restrictionManager;

    function setUp() public virtual override {
        super.setUp();
        console2.log("--- SETUP BASE SUPERVAULT ---");

        vm.selectFork(FORKS[ETH]);
        accInstances = randomAccountInstances[ETH];
        assertEq(accInstances.length, ACCOUNT_COUNT);
        superGovernor = SuperGovernor(_getContract(ETH, SUPER_GOVERNOR_KEY));
        // Get assets from fork
        asset = IERC20Metadata(existingUnderlyingTokens[ETH][USDC_KEY]);
        vm.label(address(asset), "[ETH][USDC_KEY]");

        //asset5115 = IERC20Metadata(existingUnderlyingTokens[ETH][USDE_KEY]);
        //vm.label(address(asset5115), "[ETH][USDE_KEY]");

        asset5115 = IERC20Metadata(CHAIN_1_SUSDE);
        vm.label(address(asset5115), "CHAIN_1_SUSDE");

        // Get aggregator
        aggregator = SuperVaultAggregator(_getContract(ETH, SUPER_VAULT_AGGREGATOR_KEY));

        // Deploy MockUp
        upToken = address(new MockUp(address(this)));

        // Get oracle addresses
        oracleEthToUsd = ORACLE_ETH_TO_USD;
        oracleUsdToUp = address(new MockChainlinkOracle());
        oracleGasToEth = ORACLE_GAS_TO_ETH;
        mockFeedWithRealDataEthToUsd = new MockFeedWithRealData(oracleEthToUsd);
        mockFeedWithRealDataGasToEth = new MockFeedWithRealData(oracleGasToEth);

        superOracle = ISuperOracle(_getContract(ETH, SUPER_ORACLE_KEY));

        // Deploy vault using the new _deployVault function
        (address vaultAddr, address strategyAddr, address escrowAddr) = _deployVault("SV_USDC");
        assertEq(strategyAddr, globalSVStrategy, "SV STRATEGY NOT EQUAL TO PREDICTED");

        // Now propose and execute the global hooks root update
        bytes32 root = _getMerkleRoot();
        console2.log("[DEBUG] Proposing global hooks root from explicitly generated tree");
        superGovernor.proposeGlobalHooksRoot(root);
        vm.warp(block.timestamp + 20 minutes);
        aggregator.executeGlobalHooksRootUpdate();

        // Set up accounts
        accountEth = accountInstances[ETH].account;
        instanceOnEth = accountInstances[ETH];

        accInstances = randomAccountInstances[ETH];

        // Set up super executor
        superExecutorOnEth = ISuperExecutor(_getContract(ETH, SUPER_EXECUTOR_KEY));

        // Set up SuperLedger
        superLedgerETH = ISuperLedger(_getContract(ETH, SUPER_LEDGER_KEY));
        oracle = ERC7540YieldSourceOracle(_getContract(ETH, ERC7540_YIELD_SOURCE_ORACLE_KEY));
        oracle4626 = ERC4626YieldSourceOracle(_getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY));

        // Get ECDSA Oracle
        ecdsappsOracle = IECDSAPPSOracle(_getContract(ETH, ECDSAPPS_ORACLE_KEY));

        superGovernor.proposeActivePPSOracle(address(ecdsappsOracle));
        vm.warp(block.timestamp + 7 days);
        superGovernor.executeActivePPSOracleChange();

        address fluidVaultAddr = 0x9Fb7b4477576Fe5B32be4C1843aFB1e55F251B33;
        address aaveVaultAddr = 0x73edDFa87C71ADdC275c2b9890f5c3a8480bC9E6;
        vm.label(fluidVaultAddr, "FluidVault");
        vm.label(aaveVaultAddr, "AaveVault");

        // Get real yield sources from fork
        fluidVault = IERC4626(fluidVaultAddr);
        aaveVault = IERC4626(aaveVaultAddr);

        pendleEthenaAddress = realVaultAddresses[ETH][ERC5115_VAULT_KEY][PENDLE_ETHENA_KEY][SUSDE_KEY];
        vm.label(pendleEthenaAddress, "PendleEthena");
        pendleEthena = IStandardizedYield(pendleEthenaAddress);

        vault = SuperVault(vaultAddr);
        strategy = SuperVaultStrategy(payable(strategyAddr));
        escrow = SuperVaultEscrow(escrowAddr);

        // Deploy TotalAssetHelper
        totalAssetHelper = new TotalAssetHelper();

        _setFeeConfig(100, TREASURY);

        vm.startPrank(MANAGER);
        strategy.manageYieldSource(
            address(fluidVault),
            _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY),
            0 // addYieldSource
        );
        strategy.manageYieldSource(
            address(aaveVault),
            _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY),
            0 // addYieldSource
        );
        strategy.manageYieldSource(
            address(pendleEthenaAddress),
            _getContract(ETH, ERC5115_YIELD_SOURCE_ORACLE_KEY),
            0 // addYieldSource
        );
        vm.stopPrank();

        validator1PrivateKey = 0x20;
        validator2PrivateKey = 0x30;
        validator3PrivateKey = 0x40;

        // address(this) is the super governor; no need to prank
        superGovernor.setAddress(superGovernor.UP(), upToken);
        superGovernor.setAddress(superGovernor.SUPER_ORACLE(), address(superOracle));

        //configure super oracle
        mockUSD = new MockERC20("Mock USD", "USD", 6); // USD has 6 decimals
        
        address[] memory bases = new address[](3);
        bases[0] = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
        bases[1] = address(upToken);
        bases[2] = address(uint160(uint256(keccak256("GAS_QUOTE")))); // GAS
        address[] memory quotes = new address[](3);
        quotes[0] = address(840); // USD
        quotes[1] = address(840); // USD
        quotes[2] = address(uint160(uint256(keccak256("GWEI_QUOTE")))); // GWEI
        bytes32[] memory providers = new bytes32[](3);
        providers[0] = "CHAINLINK";
        providers[1] = "CHAINLINK";
        providers[2] = "CHAINLINK";
        address[] memory feeds = new address[](3);
        feeds[0] = address(mockFeedWithRealDataEthToUsd);
        feeds[1] = oracleUsdToUp;
        feeds[2] = address(mockFeedWithRealDataGasToEth);

        // update authority is address(this); no need to prank
        superOracle.queueOracleUpdate(bases, quotes, providers, feeds);

        vm.warp(block.timestamp + 2 weeks);
        superOracle.executeOracleUpdate();

        uint256[] memory maxStaleness = new uint256[](3);
        maxStaleness[0] = 1 days;
        maxStaleness[1] = 1 days;
        maxStaleness[2] = 1 days;
        superOracle.setFeedMaxStalenessBatch(feeds, maxStaleness);

        superGovernor.setGasInfo(address(ecdsappsOracle), 10_000);

        // Centrifuge setup
        rootManager = 0x0C1fDfd6a1331a875EA013F3897fc8a76ada5DfC;
        yieldSource7540AddressETH_USDC =
            realVaultAddresses[ETH][ERC7540_FULLY_ASYNC_KEY][CENTRIFUGE_USDC_VAULT_KEY][USDC_KEY];
        vm.label(yieldSource7540AddressETH_USDC, "CentrifugeUSDCVault");
        centrifugeVault = IERC7540(yieldSource7540AddressETH_USDC);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL HELPERS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Struct to hold local variables for _deployVault to avoid stack too deep errors
     */
    struct DeployVaultVars {
        uint256 superVaultCap;
    }

    /**
     * @notice Deploys a new SuperVault with default configuration
     * @return vaultAddr The address of the deployed SuperVault
     * @return strategyAddr The address of the deployed SuperVaultStrategy
     * @return escrowAddr The address of the deployed SuperVaultEscrow
     */
    function _deployVault(
        address _asset,
        string memory _superVaultSymbol
    )
        internal
        returns (address vaultAddr, address strategyAddr, address escrowAddr)
    {
        vm.startPrank(SV_MANAGER);

        // Deploy the vault trio
        (vaultAddr, strategyAddr, escrowAddr) = aggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: _asset,
                name: "SuperVault",
                symbol: _superVaultSymbol,
                mainManager: MANAGER,
                secondaryManagers: new address[](0),
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: 1000,
                    managementFeeBps: 0,
                    recipient: address(this)
                }),
                maxUnpauseTimeLock: 0
            })
        );

        // Label the contracts for easier identification
        vm.label(vaultAddr, string.concat("SuperVault ", _superVaultSymbol));
        vm.label(strategyAddr, string.concat("SuperVaultStrategy ", _superVaultSymbol));
        vm.label(escrowAddr, string.concat("SuperVaultEscrow ", _superVaultSymbol));

        vm.stopPrank();

        return (vaultAddr, strategyAddr, escrowAddr);
    }

    /**
     * @notice Deploys a new SuperVault with default configuration
     * @param _superVaultSymbol The symbol for the SuperVault
     * @return vaultAddr The address of the deployed SuperVault
     * @return strategyAddr The address of the deployed SuperVaultStrategy
     * @return escrowAddr The address of the deployed SuperVaultEscrow
     */
    function _deployVault(string memory _superVaultSymbol)
        internal
        returns (address vaultAddr, address strategyAddr, address escrowAddr)
    {
        return _deployVault(address(asset), _superVaultSymbol);
    }

    /**
     * @notice Deploys a new SuperVault with a smart account manager
     * @param smartAccountManager The address of the smart account to use as manager
     * @return vaultAddr The address of the deployed SuperVault
     * @return strategyAddr The address of the deployed SuperVaultStrategy
     * @return escrowAddr The address of the deployed SuperVaultEscrow
     */
    function _deployVaultWithSmartAccountManager(address smartAccountManager)
        internal
        returns (address vaultAddr, address strategyAddr, address escrowAddr)
    {
        vm.startPrank(SV_MANAGER);

        // Deploy the vault trio with smart account manager
        (vaultAddr, strategyAddr, escrowAddr) = aggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                name: "SuperVault SA",
                symbol: "SV_SA_USDC",
                mainManager: smartAccountManager, // Use smart account instead of EOA
                secondaryManagers: new address[](0),
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: 1000,
                    managementFeeBps: 0,
                    recipient: address(this)
                }),
                maxUnpauseTimeLock: 0
            })
        );

        // Label the contracts for easier identification
        vm.label(vaultAddr, "SuperVault SA_USDC");
        vm.label(strategyAddr, "SuperVaultStrategy SA_USDC");
        vm.label(escrowAddr, "SuperVaultEscrow SA_USDC");

        vm.stopPrank();

        return (vaultAddr, strategyAddr, escrowAddr);
    }

    function _deployVaultWithSmartAccountManager(address smartAccountManager, address svAsset, string memory name, string memory symbol)
        internal
        returns (address vaultAddr, address strategyAddr, address escrowAddr)
    {
        vm.startPrank(SV_MANAGER);

        // Deploy the vault trio with smart account manager
        (vaultAddr, strategyAddr, escrowAddr) = aggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: svAsset,
                name: name,
                symbol: symbol,
                mainManager: smartAccountManager, // Use smart account instead of EOA
                secondaryManagers: new address[](0),
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({ performanceFeeBps: 1000, managementFeeBps: 0, recipient: address(this) })
            })
        );

        // Label the contracts for easier identification
        vm.label(vaultAddr, "SuperVault SA");
        vm.label(strategyAddr, "SuperVaultStrategy SA");
        vm.label(escrowAddr, "SuperVaultEscrow SA");

        vm.stopPrank();

        return (vaultAddr, strategyAddr, escrowAddr);
    }

    

    /**
     * @notice Sets up the SuperVault with 7540 underlying yield source
     */
    function _setUp7540UnderlyingSuperVault() internal {
        // Set the vault to use the 7540 underlying
        vm.startPrank(MANAGER);
        strategy.manageYieldSource(
            address(fluidVault),
            _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY),
            2 // removeYieldSource
        );

        strategy.manageYieldSource(
            address(centrifugeVault),
            _getContract(ETH, ERC7540_YIELD_SOURCE_ORACLE_KEY),
            0 // addYieldSource
        );
        vm.stopPrank();

        ISuperVaultStrategy.YieldSourceInfo[] memory yieldSourcesList =
            ISuperVaultStrategy(strategy).getYieldSourcesList();

        assertEq(yieldSourcesList.length, 3);
        assertEq(yieldSourcesList[1].sourceAddress, address(aaveVault));
        assertEq(yieldSourcesList[2].sourceAddress, address(centrifugeVault));

        // Centrifuge setup
        address share = centrifugeVault.share();
        address mngr = ITranche(share).hook();

        restrictionManager = RestrictionManagerLike(mngr);
        vm.startPrank(RestrictionManagerLike(mngr).root());
        restrictionManager.updateMember(share, address(strategy), type(uint64).max);
        vm.stopPrank();

        poolId = centrifugeVault.poolId();
        assertEq(poolId, 4_139_607_887);
        trancheId = centrifugeVault.trancheId();
        assertEq(trancheId, bytes16(0x97aa65f23e7be09fcd62d0554d2e9273));

        poolManager = IPoolManager(0x91808B5E2F6d7483D41A681034D7c9DbB64B9E29);
        assetId = poolManager.assetToId(address(asset));
        assertEq(assetId, uint128(242_333_941_209_166_991_950_178_742_833_476_896_417));
    }

    /**
     * @notice Sets up the SuperVault with another 4626 vault as underlying yield source
     */
    function _setUpSuperVault_With_1_Underlying_4626Vault(address newVault) internal {
        // Set the vault to use the mock loss vault as underlying yield source
        vm.startPrank(MANAGER);
        strategy.manageYieldSource(
            address(fluidVault),
            _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY),
            2 // removeYieldSource
        );
        strategy.manageYieldSource(
            address(aaveVault),
            _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY),
            2 // removeYieldSource
        );

        strategy.manageYieldSource(
            address(newVault),
            _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY),
            0 // addYieldSource
        );
        vm.stopPrank();

        ISuperVaultStrategy.YieldSourceInfo[] memory yieldSourcesList =
            ISuperVaultStrategy(strategy).getYieldSourcesList();

        assertEq(yieldSourcesList.length, 1);
        assertEq(yieldSourcesList[0].sourceAddress, address(newVault));
    }

    /**
     * @notice Helper function to manage yield sources via smart account manager
     * @param managerAccount The smart account that will execute the management calls
     * @param targetStrategy The strategy to manage yield sources for
     */
    function _manageYieldSourcesViaSmartAccount(
        AccountInstance memory managerAccount,
        SuperVaultStrategy targetStrategy
    )
        internal
    {
        // Create ManageYieldSourcesArgs for both vaults
        address[] memory sources = new address[](3);
        sources[0] = address(fluidVault);
        sources[1] = address(aaveVault);
        sources[2] = address(pendleEthenaAddress);

        address[] memory oracles = new address[](3);
        oracles[0] = _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY);
        oracles[1] = _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY);
        oracles[2] = _getContract(ETH, ERC5115_YIELD_SOURCE_ORACLE_KEY);

        uint8[] memory actionTypes = new uint8[](3);
        actionTypes[0] = 0; // Add yield source
        actionTypes[1] = 0; // Add yield source
        actionTypes[2] = 0; // Add yield source

        SuperVaultManageYieldSourceHook.ManageYieldSourcesArgs memory args = SuperVaultManageYieldSourceHook
            .ManageYieldSourcesArgs({ sources: sources, oracles: oracles, actionTypes: actionTypes });

        // Deploy the SuperVaultManageYieldSourceHook
        address manageYieldSourceHook = address(new SuperVaultManageYieldSourceHook(address(targetStrategy)));

        // Execute via the smart account using our custom hook
        address[] memory hooksAddresses = new address[](1);
        hooksAddresses[0] = manageYieldSourceHook;

        bytes[] memory hooksData = new bytes[](1);
        hooksData[0] = abi.encode(args);

        ISuperExecutor.ExecutorEntry memory entry =
            ISuperExecutor.ExecutorEntry({ hooksAddresses: hooksAddresses, hooksData: hooksData });
        UserOpData memory userOpData = _getExecOps(managerAccount, superExecutorOnEth, abi.encode(entry));
        executeOp(userOpData);
    }

    function __deposit(AccountInstance memory accInst, uint256 depositAmount) internal {
        address[] memory hooksAddresses = new address[](1);
        hooksAddresses[0] = _getHookAddress(ETH, APPROVE_AND_REQUEST_DEPOSIT_7540_VAULT_HOOK_KEY);

        bytes[] memory hooksData = new bytes[](1);
        hooksData[0] = _createApproveAndRequestDeposit7540HookData(
            //_getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            address(vault),
            address(asset),
            depositAmount,
            false
        );

        ISuperExecutor.ExecutorEntry memory entry =
            ISuperExecutor.ExecutorEntry({ hooksAddresses: hooksAddresses, hooksData: hooksData });
        UserOpData memory userOpData = _getExecOps(accInst, superExecutorOnEth, abi.encode(entry));
        executeOp(userOpData);

        vm.startPrank(MANAGER);
        address[] memory controllers = new address[](1);
        controllers[0] = address(accInst.account);
        strategy.fulfillDepositRequest(controllers);
        vm.stopPrank();
    }

    function __deposit(
        AccountInstance memory accInst,
        uint256 depositAmount,
        address superVault,
        address asset_
    )
        internal
    {
        address[] memory hooksAddresses = new address[](1);
        hooksAddresses[0] = _getHookAddress(ETH, APPROVE_AND_REQUEST_DEPOSIT_7540_VAULT_HOOK_KEY);

        bytes[] memory hooksData = new bytes[](1);
        hooksData[0] = _createApproveAndRequestDeposit7540HookData(
            //_getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            superVault,
            asset_,
            depositAmount,
            false
        );

        ISuperExecutor.ExecutorEntry memory entry =
            ISuperExecutor.ExecutorEntry({ hooksAddresses: hooksAddresses, hooksData: hooksData });
        UserOpData memory userOpData = _getExecOps(accInst, superExecutorOnEth, abi.encode(entry));
        executeOp(userOpData);
        
        vm.startPrank(MANAGER);
        address[] memory controllers = new address[](1);
        controllers[0] = address(accInst.account);
        strategy.fulfillDepositRequest(controllers);
        vm.stopPrank();
    }


    function __deposit5115(
        AccountInstance memory accInst,
        uint256 depositAmount,
        address superVault_,
        address asset_
    )
        internal
    {
        address[] memory hooksAddresses = new address[](1);
        hooksAddresses[0] = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_5115_VAULT_HOOK_KEY);

        bytes[] memory hooksData = new bytes[](1);
        hooksData[0] = _createApproveAndDeposit5115HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC5115_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            superVault_,
            asset_,
            depositAmount,
            0,
            false
        );

        ISuperExecutor.ExecutorEntry memory entry =
            ISuperExecutor.ExecutorEntry({ hooksAddresses: hooksAddresses, hooksData: hooksData });
        UserOpData memory userOpData = _getExecOps(accInst, superExecutorOnEth, abi.encode(entry));
        executeOp(userOpData);
    }


    /*
    Leaving commented for now
    function __requestDeposit(AccountInstance memory accInst, uint256 depositAmount) internal {
        address[] memory hooksAddresses = new address[](1);
        hooksAddresses[0] = _getHookAddress(ETH, APPROVE_AND_REQUEST_DEPOSIT_7540_VAULT_HOOK_KEY);

        bytes[] memory hooksData = new bytes[](1);
    hooksData[0] = _createApproveAndRequestDeposit7540HookData(address(vault), address(asset), depositAmount, false);

        ISuperExecutor.ExecutorEntry memory entry =
            ISuperExecutor.ExecutorEntry({ hooksAddresses: hooksAddresses, hooksData: hooksData });
        UserOpData memory userOpData = _getExecOps(accInst, superExecutorOnEth, abi.encode(entry));
        executeOp(userOpData);
    }

    function __claimDeposit(AccountInstance memory accInst, uint256 depositAmount) internal {
        address[] memory claimHooksAddresses = new address[](1);
        claimHooksAddresses[0] = _getHookAddress(ETH, DEPOSIT_7540_VAULT_HOOK_KEY);

        bytes[] memory claimHooksData = new bytes[](1);
        claimHooksData[0] = _createDeposit7540VaultHookData(
    _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER), address(vault), depositAmount,
    false, false
        );

        ISuperExecutor.ExecutorEntry memory claimEntry =
            ISuperExecutor.ExecutorEntry({ hooksAddresses: claimHooksAddresses, hooksData: claimHooksData });
        UserOpData memory claimUserOpData = _getExecOps(accInst, superExecutorOnEth, abi.encode(claimEntry));
        executeOp(claimUserOpData);
    }
    */

    function __requestRedeem(AccountInstance memory accInst, uint256 redeemShares, bool shouldRevert) internal {
        address[] memory redeemHooksAddresses = new address[](1);
        redeemHooksAddresses[0] = _getHookAddress(ETH, REQUEST_REDEEM_7540_VAULT_HOOK_KEY);

        bytes[] memory redeemHooksData = new bytes[](1);
        redeemHooksData[0] = _createRequestRedeem7540VaultHookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC7540_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            address(vault),
            redeemShares,
            false
        );

        console2.log("__requestRedeem ------ redeemShares", redeemShares);

        ISuperExecutor.ExecutorEntry memory redeemEntry =
            ISuperExecutor.ExecutorEntry({ hooksAddresses: redeemHooksAddresses, hooksData: redeemHooksData });
        UserOpData memory redeemUserOpData = _getExecOps(accInst, superExecutorOnEth, abi.encode(redeemEntry));

        if (shouldRevert) {
            accInst.expect4337Revert();
        }
        executeOp(redeemUserOpData);
    }

    function __requestRedeem(
        AccountInstance memory accInst,
        uint256 redeemShares,
        bool shouldRevert,
        address superVault
    )
        internal
    {
        address[] memory redeemHooksAddresses = new address[](1);
        redeemHooksAddresses[0] = _getHookAddress(ETH, REQUEST_REDEEM_7540_VAULT_HOOK_KEY);

        bytes[] memory redeemHooksData = new bytes[](1);
        redeemHooksData[0] = _createRequestRedeem7540VaultHookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC7540_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            superVault,
            redeemShares,
            false
        );

        ISuperExecutor.ExecutorEntry memory redeemEntry =
            ISuperExecutor.ExecutorEntry({ hooksAddresses: redeemHooksAddresses, hooksData: redeemHooksData });
        UserOpData memory redeemUserOpData = _getExecOps(accInst, superExecutorOnEth, abi.encode(redeemEntry));

        if (shouldRevert) {
            accInst.expect4337Revert();
        }
        executeOp(redeemUserOpData);
    }


    function __claimWithdraw(AccountInstance memory accInst, uint256 assets) internal {
        address[] memory claimHooksAddresses = new address[](1);
        claimHooksAddresses[0] = _getHookAddress(ETH, WITHDRAW_7540_VAULT_HOOK_KEY);

        bytes[] memory claimHooksData = new bytes[](1);
        claimHooksData[0] = _createWithdraw7540VaultHookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            address(vault),
            assets,
            false
        );

        ISuperExecutor.ExecutorEntry memory claimEntry =
            ISuperExecutor.ExecutorEntry({ hooksAddresses: claimHooksAddresses, hooksData: claimHooksData });
        UserOpData memory claimUserOpData = _getExecOps(accInst, superExecutorOnEth, abi.encode(claimEntry));
        executeOp(claimUserOpData);
    }

    function _claimRedeem(uint256 shares) internal {
        __claimRedeem(instanceOnEth, shares);
    }

    function __claimRedeem(AccountInstance memory accInst, uint256 shares) internal {
        address[] memory claimHooksAddresses = new address[](1);
        claimHooksAddresses[0] = _getHookAddress(ETH, REDEEM_7540_VAULT_HOOK_KEY);

        bytes[] memory claimHooksData = new bytes[](1);
        claimHooksData[0] = _createRedeem7540VaultHookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            address(vault),
            shares,
            false
        );

        ISuperExecutor.ExecutorEntry memory claimEntry =
            ISuperExecutor.ExecutorEntry({ hooksAddresses: claimHooksAddresses, hooksData: claimHooksData });
        UserOpData memory claimUserOpData = _getExecOps(accInst, superExecutorOnEth, abi.encode(claimEntry));
        executeOp(claimUserOpData);
    }

    function _claimRedeemForAccount(AccountInstance memory accInst, uint256 shares) internal {
        __claimRedeem(accInst, shares);
    }

    function __claimWithdraw5115(AccountInstance memory accInst, uint256 assets, address _svVault) internal {
        address[] memory claimHooksAddresses = new address[](1);
        claimHooksAddresses[0] = _getHookAddress(ETH, WITHDRAW_7540_VAULT_HOOK_KEY);

        bytes[] memory claimHooksData = new bytes[](1);
        claimHooksData[0] = _createWithdraw7540VaultHookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC7540_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            _svVault,
            assets,
            false
        );

        ISuperExecutor.ExecutorEntry memory claimEntry =
            ISuperExecutor.ExecutorEntry({ hooksAddresses: claimHooksAddresses, hooksData: claimHooksData });
        UserOpData memory claimUserOpData = _getExecOps(accInst, superExecutorOnEth, abi.encode(claimEntry));
        executeOp(claimUserOpData);
    }

    function _deposit(uint256 depositAmount) internal {
        __deposit(instanceOnEth, depositAmount);
    }

    function _deposit(uint256 depositAmount, address superVault, address asset_) internal {
        __deposit(instanceOnEth, depositAmount, superVault, asset_);
    }

    function _deposit(uint256 depositAmount, address superVault, address strat, address asset_) internal {
        __deposit(instanceOnEth, depositAmount, superVault, strat, asset_);
    }


    function _depositForAccount(AccountInstance memory accInst, uint256 depositAmount) internal {
        __deposit(accInst, depositAmount);
    }

    function _depositForAllUsers(uint256 depositAmount) internal {
        for (uint256 i; i < ACCOUNT_COUNT; ++i) {
            _getTokens(address(asset), accInstances[i].account, depositAmount);
            _depositForAccount(accInstances[i], depositAmount);
        }
    }

    //todo: this needs to be renamed / moved
    function _deposit5115(uint256 depositAmount, address superVault, address asset_) internal {
        __deposit5115(instanceOnEth, depositAmount, superVault, asset_);
    }

    /*
        Leaving commented for now

    function _claimDeposit(uint256 depositAmount) internal {
        __claimDeposit(instanceOnEth, depositAmount);
    }

    function _claimDepositForAccount(AccountInstance memory accInst, uint256 depositAmount) internal {
        __claimDeposit(accInst, depositAmount);
    }
    */

    function _requestRedeem(uint256 redeemShares) internal {
        __requestRedeem(instanceOnEth, redeemShares, false);
    }

    function _requestRedeem(uint256 redeemShares, address superVault) internal {
        __requestRedeem(instanceOnEth, redeemShares, false, superVault);
    }

    function _requestRedeemForAccount(AccountInstance memory accInst, uint256 redeemShares) internal {
        __requestRedeem(accInst, redeemShares, false);
    }

    function _requestRedeemForAccount_Revert(AccountInstance memory accInst, uint256 redeemShares) internal {
        __requestRedeem(accInst, redeemShares, true);
    }

    function _requestRedeemForAllUsers(uint256 redeemAmount) internal {
        for (uint256 i; i < ACCOUNT_COUNT; ++i) {
            uint256 redeemShares = redeemAmount > 0 ? redeemAmount : vault.balanceOf(accInstances[i].account);
            _requestRedeemForAccount(accInstances[i], redeemShares);
        }
    }

    function _claimWithdrawForAccount(AccountInstance memory accInst, uint256 assets) internal {
        __claimWithdraw(accInst, assets);
    }

    function _claimWithdraw(uint256 assets) internal {
        __claimWithdraw(instanceOnEth, assets);
    }

    function _claimWithdraw5115(uint256 assets, address svVault) internal {
        __claimWithdraw5115(instanceOnEth, assets, svVault);
    }

    function _depositFreeAssetsFromSingleAmount(uint256 depositAmount, address vault1, address vault2) internal {
        _depositFreeAssetsFromSingleAmount(depositAmount, address(strategy), address(asset), vault1, vault2);
    }


    function _depositFreeAssetsFromSingleAmount(uint256 depositAmount, address strat, address vault1, address vault2) internal {
        _depositFreeAssetsFromSingleAmount(depositAmount, strat, address(asset), vault1, vault2);
    }

    function _depositFreeAssetsFromSingleAmount(uint256 depositAmount, address strat, address assetToDeposit, address vault1, address vault2) internal {
        (
            address[] memory fulfillHooksAddresses,
            bytes[] memory fulfillHooksData,
            uint256[] memory expectedAssetsOrSharesOut
        ) = __prepareDepositHookData(depositAmount, assetToDeposit, vault1, vault2);
        
        __executeDepositHooks(depositAmount, strat, fulfillHooksAddresses, fulfillHooksData, expectedAssetsOrSharesOut);
    } 

    function _depositFreeAssetsFromSingleAmount5115(uint256 depositAmount, address strategyAddress, address underlyingVault) internal {
        address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_5115_VAULT_HOOK_KEY);

        address[] memory fulfillHooksAddresses = new address[](1);
        fulfillHooksAddresses[0] = depositHookAddress;

        bytes[] memory fulfillHooksData = new bytes[](1);
        // Split the deposit between two hooks

        fulfillHooksData[0] = _createApproveAndDeposit5115HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC5115_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            underlyingVault,
            address(asset5115),
            depositAmount,
            0,
            false
        );
       

        uint256[] memory expectedAssetsOrSharesOut = new uint256[](1);
        expectedAssetsOrSharesOut[0] = IStandardizedYield(address(underlyingVault)).previewDeposit(address(asset5115), depositAmount);

        bytes[] memory argsForProofs = new bytes[](1);
        argsForProofs[0] = ISuperHookInspector(fulfillHooksAddresses[0]).inspect(fulfillHooksData[0]);

        vm.startPrank(MANAGER);
        SuperVaultStrategy(payable(strategyAddress)).executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: fulfillHooksAddresses,
                hookCalldata: fulfillHooksData,
                expectedAssetsOrSharesOut: expectedAssetsOrSharesOut,
                globalProofs: _getMerkleProofsForHooks(fulfillHooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](1)
            })
        );
        vm.stopPrank();

        (uint256 pricePerShare) = _getSuperVaultPricePerShare();
        uint256 shares = depositAmount.mulDiv(strategy.PRECISION(), pricePerShare);

        _trackDeposit(accountEth, shares, depositAmount);
    }

    function _depositFreeAssetsFromSingleAmountViaSmartAccount5115(
        uint256 depositAmount,
        address underlyingVault,
        AccountInstance memory managerAccount,
        SuperVaultStrategy targetStrategy
    )
        internal
    {
        DepositViaSmartAccountVars memory vars;

        vars.depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_5115_VAULT_HOOK_KEY);

        vars.fulfillHooksAddresses = new address[](1);
        vars.fulfillHooksAddresses[0] = vars.depositHookAddress;

        vars.fulfillHooksData = new bytes[](1);
        vars.fulfillHooksData[0] = _createApproveAndDeposit5115HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC5115_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            underlyingVault,
            address(asset5115),
            depositAmount,
            0,
            false
        );


        vars.expectedAssetsOrSharesOut = new uint256[](1);
        vars.expectedAssetsOrSharesOut[0] = IStandardizedYield(address(underlyingVault)).previewDeposit(address(asset5115), depositAmount);

        vars.argsForProofs = new bytes[](1);
        vars.argsForProofs[0] = ISuperHookInspector(vars.fulfillHooksAddresses[0]).inspect(vars.fulfillHooksData[0]);

        // Create the ExecuteArgs for the strategy
        vars.executeArgs = ISuperVaultStrategy.ExecuteArgs({
            hooks: vars.fulfillHooksAddresses,
            hookCalldata: vars.fulfillHooksData,
            expectedAssetsOrSharesOut: vars.expectedAssetsOrSharesOut,
            globalProofs: _getMerkleProofsForHooks(vars.fulfillHooksAddresses, vars.argsForProofs),
            strategyProofs: new bytes32[][](1)
        });

        // Deploy the SuperVaultExecuteHooksHook
        vars.executeHooksHook = address(new SuperVaultExecuteHooksHook(address(targetStrategy)));

        // Execute via the smart account using our custom hook
        vars.hooksAddresses = new address[](1);
        vars.hooksAddresses[0] = vars.executeHooksHook;

        vars.hooksData = new bytes[](1);
        vars.hooksData[0] = abi.encode(vars.executeArgs);

        vars.entry = ISuperExecutor.ExecutorEntry({ hooksAddresses: vars.hooksAddresses, hooksData: vars.hooksData });
        vars.userOpData = _getExecOps(managerAccount, superExecutorOnEth, abi.encode(vars.entry));
        executeOp(vars.userOpData);

        (vars.pricePerShare) = _getSuperVaultPricePerShare();
        vars.shares = depositAmount.mulDiv(targetStrategy.PRECISION(), vars.pricePerShare);

        _trackDeposit(accountEth, vars.shares, depositAmount);
    }


    function _depositFreeAssetsFromSingleAmountViaSmartAccount(
        uint256 depositAmount,
        address vault1,
        address vault2,
        AccountInstance memory managerAccount,
        SuperVaultStrategy targetStrategy
    )
        internal
    {
        DepositViaSmartAccountVars memory vars;

        vars.depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        vars.fulfillHooksAddresses = new address[](2);
        vars.fulfillHooksAddresses[0] = vars.depositHookAddress;
        vars.fulfillHooksAddresses[1] = vars.depositHookAddress;

        vars.fulfillHooksData = new bytes[](2);

        // Split the deposit between two hooks
        vars.halfAmount = depositAmount / 2;
        vars.fulfillHooksData[0] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            vault1,
            address(asset),
            vars.halfAmount,
            false,
            address(0),
            0
        );

        vars.fulfillHooksData[1] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            vault2,
            address(asset),
            depositAmount - vars.halfAmount,
            false,
            address(0),
            0
        );

        vars.expectedAssetsOrSharesOut = new uint256[](2);
        vars.expectedAssetsOrSharesOut[0] = IERC4626(address(vault1)).convertToShares(vars.halfAmount);
        vars.expectedAssetsOrSharesOut[1] = IERC4626(address(vault2)).convertToShares(depositAmount - vars.halfAmount);

        vars.argsForProofs = new bytes[](2);
        vars.argsForProofs[0] = ISuperHookInspector(vars.fulfillHooksAddresses[0]).inspect(vars.fulfillHooksData[0]);
        vars.argsForProofs[1] = ISuperHookInspector(vars.fulfillHooksAddresses[1]).inspect(vars.fulfillHooksData[1]);

        // Create the ExecuteArgs for the strategy
        vars.executeArgs = ISuperVaultStrategy.ExecuteArgs({
            hooks: vars.fulfillHooksAddresses,
            hookCalldata: vars.fulfillHooksData,
            expectedAssetsOrSharesOut: vars.expectedAssetsOrSharesOut,
            globalProofs: _getMerkleProofsForHooks(vars.fulfillHooksAddresses, vars.argsForProofs),
            strategyProofs: new bytes32[][](2)
        });

        // Deploy the SuperVaultExecuteHooksHook
        vars.executeHooksHook = address(new SuperVaultExecuteHooksHook(address(targetStrategy)));

        // Execute via the smart account using our custom hook
        vars.hooksAddresses = new address[](1);
        vars.hooksAddresses[0] = vars.executeHooksHook;

        vars.hooksData = new bytes[](1);
        vars.hooksData[0] = abi.encode(vars.executeArgs);

        vars.entry = ISuperExecutor.ExecutorEntry({ hooksAddresses: vars.hooksAddresses, hooksData: vars.hooksData });
        vars.userOpData = _getExecOps(managerAccount, superExecutorOnEth, abi.encode(vars.entry));
        executeOp(vars.userOpData);

        (vars.pricePerShare) = _getSuperVaultPricePerShare();
        vars.shares = depositAmount.mulDiv(targetStrategy.PRECISION(), vars.pricePerShare);

        _trackDeposit(accountEth, vars.shares, depositAmount);
    }

    function _depositFreeAssetsFromSingleAmount7540(uint256 depositAmount, address vault1, address vault2) internal {
        uint256 halfAmount = depositAmount / 2;

        // Request deposit to the underlying 7540 vault
        address[] memory requestHooks = new address[](1);
        requestHooks[0] = _getHookAddress(ETH, APPROVE_AND_REQUEST_DEPOSIT_7540_VAULT_HOOK_KEY);

        bytes[] memory requestHooksData = new bytes[](1);
        requestHooksData[0] = _createApproveAndRequestDeposit7540HookData(vault2, address(asset), halfAmount, false);

        bytes[] memory argsForRequestProofs = new bytes[](1);
        argsForRequestProofs[0] = ISuperHookInspector(requestHooks[0]).inspect(requestHooksData[0]);

        uint256[] memory expectedRequestAssetsOrSharesOut = new uint256[](1);
        expectedRequestAssetsOrSharesOut[0] = 0;

        vm.startPrank(MANAGER);
        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: requestHooks,
                hookCalldata: requestHooksData,
                expectedAssetsOrSharesOut: expectedRequestAssetsOrSharesOut,
                globalProofs: _getMerkleProofsForHooks(requestHooks, argsForRequestProofs),
                strategyProofs: new bytes32[][](1)
            })
        );
        vm.stopPrank();

        // Fulfill the deposit request from the underlying 7540 vault
        _fulfill7540UnderlyingRequest(halfAmount);

        // Create the deposit hooks and data
        {
            address deposit4626HookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);
            address deposit7540HookAddress = _getHookAddress(ETH, DEPOSIT_7540_VAULT_HOOK_KEY);

            address[] memory fulfillHooksAddresses = new address[](2);
            fulfillHooksAddresses[0] = deposit4626HookAddress;
            fulfillHooksAddresses[1] = deposit7540HookAddress;

            bytes[] memory fulfillHooksData = new bytes[](2);

            // Split the deposit between two hooks
            fulfillHooksData[0] = _createApproveAndDeposit4626HookData(
                _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
                vault1,
                address(asset),
                halfAmount,
                false,
                address(0),
                0
            );

            uint256 maxDeposit = centrifugeVault.maxDeposit(address(strategy));
            uint256 vaultExpectedShares = centrifugeVault.convertToShares(maxDeposit);

            fulfillHooksData[1] = _createDeposit7540VaultHookData(
                _getYieldSourceOracleId(bytes32(bytes(ERC7540_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
                address(centrifugeVault),
                maxDeposit,
                false,
                address(0),
                0
            );

            uint256[] memory expectedAssetsOrSharesOut = new uint256[](2);
            expectedAssetsOrSharesOut[0] = IERC4626(address(vault1)).convertToShares(halfAmount);
            expectedAssetsOrSharesOut[1] = vaultExpectedShares;

            bytes[] memory argsForProofs = new bytes[](2);
            argsForProofs[0] = ISuperHookInspector(fulfillHooksAddresses[0]).inspect(fulfillHooksData[0]);
            argsForProofs[1] = ISuperHookInspector(fulfillHooksAddresses[1]).inspect(fulfillHooksData[1]);

            vm.startPrank(MANAGER);
            strategy.executeHooks(
                ISuperVaultStrategy.ExecuteArgs({
                    hooks: fulfillHooksAddresses,
                    hookCalldata: fulfillHooksData,
                    expectedAssetsOrSharesOut: expectedAssetsOrSharesOut,
                    globalProofs: _getMerkleProofsForHooks(fulfillHooksAddresses, argsForProofs),
                    strategyProofs: new bytes32[][](2)
                })
            );
            vm.stopPrank();
        }

        (uint256 pricePerShare) = _getSuperVaultPricePerShare();
        uint256 shares = depositAmount.mulDiv(strategy.PRECISION(), pricePerShare);

        _trackDeposit(accountEth, shares, depositAmount);
    }

    function _fulfill7540UnderlyingRequest(uint256 depositAmount) internal {
        uint256 vaultExpectedShares = centrifugeVault.convertToShares(depositAmount);

        investmentManager = IInvestmentManager(0xE79f06573d6aF1B66166A926483ba00924285d20);

        vm.prank(rootManager);
        investmentManager.fulfillDepositRequest(
            poolId, trancheId, address(strategy), assetId, uint128(depositAmount), uint128(vaultExpectedShares)
        );
    }

    function _depositFreeAssets_Into_Underlying_4626Vault(uint256 depositAmount, address underlyingVault) internal {
        address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        address[] memory fulfillHooksAddresses = new address[](1);
        fulfillHooksAddresses[0] = depositHookAddress;

        bytes[] memory fulfillHooksData = new bytes[](1);

        // Split the deposit between two hooks
        fulfillHooksData[0] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            underlyingVault,
            address(asset),
            depositAmount,
            false,
            address(0),
            0
        );

        uint256[] memory expectedAssetsOrSharesOut = new uint256[](1);
        expectedAssetsOrSharesOut[0] = IERC4626(address(underlyingVault)).convertToShares(depositAmount);

        bytes[] memory argsForProofs = new bytes[](1);
        argsForProofs[0] = ISuperHookInspector(fulfillHooksAddresses[0]).inspect(fulfillHooksData[0]);

        vm.startPrank(MANAGER);
        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: fulfillHooksAddresses,
                hookCalldata: fulfillHooksData,
                expectedAssetsOrSharesOut: expectedAssetsOrSharesOut,
                globalProofs: _getMerkleProofsForHooks(fulfillHooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](1)
            })
        );
        vm.stopPrank();

        (uint256 pricePerShare) = _getSuperVaultPricePerShare();
        uint256 shares = depositAmount.mulDiv(strategy.PRECISION(), pricePerShare);

        _trackDeposit(accountEth, shares, depositAmount);
    }

    // Local variables struct for _depositFreeAssetsFromSingleAmountViaSmartAccount
    struct DepositViaSmartAccountVars {
        address depositHookAddress;
        address[] fulfillHooksAddresses;
        bytes[] fulfillHooksData;
        uint256 halfAmount;
        uint256[] expectedAssetsOrSharesOut;
        bytes[] argsForProofs;
        ISuperVaultStrategy.ExecuteArgs executeArgs;
        address executeHooksHook;
        address[] hooksAddresses;
        bytes[] hooksData;
        ISuperExecutor.ExecutorEntry entry;
        UserOpData userOpData;
        uint256 pricePerShare;
        uint256 shares;
    }

    // Local variables struct for _fulfillRedeem
    struct FulfillRedeemLocalVars {
        address[] requestingUsers;
        address withdrawHookAddress;
        address[] fulfillHooksAddresses;
        uint256 fluidSharesOut;
        uint256 aaveSharesOut;
        bytes[] fulfillHooksData;
        uint256 totalSvAssets;
        uint256 pricePerShare;
        uint256 amountForVault1;
        uint256 amountForVault2;
        uint256 underlyingSharesForVault1;
        uint256 underlyingSharesForVault2;
        uint256[] expectedAssetsOrSharesOut;
    }

    // Local variables struct for _depositFreeAssets with 3 vaults
    struct DepositFreeAssetsVars {
        address depositHookAddress;
        address[] fulfillHooksAddresses;
        bytes[] fulfillHooksData;
        uint256[] expectedAssetsOrSharesOut;
        bytes[] argsForProofs;
        bytes32 yieldSourceOracleId;
        address assetAddress;
        ISuperVaultStrategy.ExecuteArgs executeArgs;
    }

    function _fulfillRedeem(uint256 redeemShares, address vault1, address vault2) internal {
        /// @dev with preserve percentages based on USD value allocation
        FulfillRedeemLocalVars memory vars;

        vars.requestingUsers = new address[](1);
        vars.requestingUsers[0] = accountEth;
        vars.withdrawHookAddress = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);

        vars.fulfillHooksAddresses = new address[](2);
        vars.fulfillHooksAddresses[0] = vars.withdrawHookAddress;
        vars.fulfillHooksAddresses[1] = vars.withdrawHookAddress;

        (vars.fluidSharesOut, vars.aaveSharesOut) = _calculateVaultShares(redeemShares);

        vars.fulfillHooksData = new bytes[](2);
        // Withdraw proportionally from both vaults based on USD value allocation
        vars.fulfillHooksData[0] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            vault1,
            address(strategy),
            vars.fluidSharesOut,
            false
        );

        vars.fulfillHooksData[1] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            vault2,
            address(strategy),
            vars.aaveSharesOut,
            false
        );

        (vars.totalSvAssets,) = totalAssetHelper.totalAssets(address(strategy));
        vars.pricePerShare = vars.totalSvAssets.mulDiv(strategy.PRECISION(), vault.totalSupply(), Math.Rounding.Floor);

        vars.amountForVault1 = vars.fluidSharesOut * vault.PRECISION() / vars.pricePerShare;
        vars.amountForVault2 = vars.aaveSharesOut * vault.PRECISION() / vars.pricePerShare;

        vars.underlyingSharesForVault1 = IERC4626(address(vault1)).convertToShares(vars.amountForVault1);
        vars.underlyingSharesForVault2 = IERC4626(address(vault2)).convertToShares(vars.amountForVault2);

        vars.expectedAssetsOrSharesOut = new uint256[](2);
        vars.expectedAssetsOrSharesOut[0] = IERC4626(address(vault1)).convertToAssets(vars.underlyingSharesForVault1);
        vars.expectedAssetsOrSharesOut[1] = IERC4626(address(vault2)).convertToAssets(vars.underlyingSharesForVault2);

        for (uint256 i; i < vars.expectedAssetsOrSharesOut.length; i++) {
            vars.expectedAssetsOrSharesOut[i] = vars.expectedAssetsOrSharesOut[i] - vars.expectedAssetsOrSharesOut[i] * 1e3 / 1e5;
        }

        vm.startPrank(MANAGER);
        bytes[] memory argsForProofs = new bytes[](2);
        argsForProofs[0] = ISuperHookInspector(vars.fulfillHooksAddresses[0]).inspect(vars.fulfillHooksData[0]);
        argsForProofs[1] = ISuperHookInspector(vars.fulfillHooksAddresses[1]).inspect(vars.fulfillHooksData[1]);

        strategy.fulfillRedeemRequests(
            ISuperVaultStrategy.FulfillArgs({
                controllers: vars.requestingUsers,
                hooks: vars.fulfillHooksAddresses,
                hookCalldata: vars.fulfillHooksData,
                expectedAssetsOrSharesOut: vars.expectedAssetsOrSharesOut,
                globalProofs: _getMerkleProofsForHooks(vars.fulfillHooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](2)
            })
        );
        vm.stopPrank();
    }

    function _fulfillRedeem_Single_YieldSource(uint256 redeemShares, address underlyingVault) internal {
        address[] memory fulfillHooksAddresses = new address[](1);
        fulfillHooksAddresses[0] = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);

        bytes[] memory fulfillHooksData = new bytes[](1);
        fulfillHooksData[0] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            underlyingVault,
            address(strategy),
            redeemShares,
            false
        );

        uint256[] memory expectedAssetsOrSharesOut = new uint256[](1);
        expectedAssetsOrSharesOut[0] = IERC4626(address(underlyingVault)).convertToAssets(redeemShares);

        bytes[] memory argsForProofs = new bytes[](1);
        argsForProofs[0] = ISuperHookInspector(fulfillHooksAddresses[0]).inspect(fulfillHooksData[0]);

        address[] memory requestingUsers = new address[](1);
        requestingUsers[0] = accountEth;

        vm.prank(MANAGER);
        strategy.fulfillRedeemRequests(
            ISuperVaultStrategy.FulfillArgs({
                controllers: requestingUsers,
                hooks: fulfillHooksAddresses,
                hookCalldata: fulfillHooksData,
                expectedAssetsOrSharesOut: expectedAssetsOrSharesOut,
                globalProofs: _getMerkleProofsForHooks(fulfillHooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](1)
            })
        );
        vm.stopPrank();
    }

    function _fulfillRedeem5115(uint256 redeemShares, address svAddr, address strat) internal {
        /// @dev with preserve percentages based on USD value allocation
        FulfillRedeemLocalVars memory vars;

        vars.requestingUsers = new address[](1);
        vars.requestingUsers[0] = accountEth;
        vars.withdrawHookAddress = _getHookAddress(ETH, REDEEM_5115_VAULT_HOOK_KEY);

        vars.fulfillHooksAddresses = new address[](1);
        vars.fulfillHooksAddresses[0] = vars.withdrawHookAddress;

        uint256 vaultShare = pendleEthena.previewRedeem(CHAIN_1_SUSDE, redeemShares);

        vars.fulfillHooksData = new bytes[](1);
        // Withdraw proportionally from both vaults based on USD value allocation
        vars.fulfillHooksData[0] = _create5115RedeemHookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC5115_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            pendleEthenaAddress,
            CHAIN_1_SUSDE,
            vaultShare,
            0,
            false
        );

        (vars.totalSvAssets,) = totalAssetHelper.totalAssets(address(strat));
        vars.pricePerShare = vars.totalSvAssets.mulDiv(SuperVaultStrategy(payable(strat)).PRECISION(), SuperVault(svAddr).totalSupply(), Math.Rounding.Floor);

        vars.amountForVault1 = vaultShare * SuperVault(svAddr).PRECISION() / vars.pricePerShare;
        vars.underlyingSharesForVault1 = pendleEthena.previewDeposit(address(asset5115), vars.amountForVault1);

        vars.expectedAssetsOrSharesOut = new uint256[](1);
        vars.expectedAssetsOrSharesOut[0] = pendleEthena.previewRedeem(CHAIN_1_SUSDE, vars.underlyingSharesForVault1);

        vm.startPrank(MANAGER);
        bytes[] memory argsForProofs = new bytes[](1);
        argsForProofs[0] = ISuperHookInspector(vars.fulfillHooksAddresses[0]).inspect(vars.fulfillHooksData[0]);

        SuperVaultStrategy(payable(strat)).fulfillRedeemRequests(
            ISuperVaultStrategy.FulfillArgs({
                controllers: vars.requestingUsers,
                hooks: vars.fulfillHooksAddresses,
                hookCalldata: vars.fulfillHooksData,
                expectedAssetsOrSharesOut: vars.expectedAssetsOrSharesOut,
                globalProofs: _getMerkleProofsForHooks(vars.fulfillHooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](1)
            })
        );
        vm.stopPrank();
    }

    function _depositFreeAssets(
        uint256 allocationAmountVault1,
        uint256 allocationAmountVault2,
        address vault1,
        address vault2
    )
        internal
    {
        address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        address[] memory fulfillHooksAddresses = new address[](2);
        fulfillHooksAddresses[0] = depositHookAddress;
        fulfillHooksAddresses[1] = depositHookAddress;

        bytes[] memory fulfillHooksData = new bytes[](2);
        // allocate up to the max allocation rate in the two Vaults
        fulfillHooksData[0] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            vault1,
            address(asset),
            allocationAmountVault1,
            false,
            address(0),
            0
        );
        fulfillHooksData[1] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            vault2,
            address(asset),
            allocationAmountVault2,
            false,
            address(0),
            0
        );

        uint256[] memory expectedAssetsOrSharesOut = new uint256[](2);
        expectedAssetsOrSharesOut[0] = IERC4626(address(vault1)).convertToShares(allocationAmountVault1);
        expectedAssetsOrSharesOut[1] = IERC4626(address(vault2)).convertToShares(allocationAmountVault2);

        vm.startPrank(MANAGER);
        bytes[] memory argsForProofs = new bytes[](2);
        argsForProofs[0] = ISuperHookInspector(fulfillHooksAddresses[0]).inspect(fulfillHooksData[0]);
        argsForProofs[1] = ISuperHookInspector(fulfillHooksAddresses[1]).inspect(fulfillHooksData[1]);

        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: fulfillHooksAddresses,
                hookCalldata: fulfillHooksData,
                expectedAssetsOrSharesOut: expectedAssetsOrSharesOut,
                globalProofs: _getMerkleProofsForHooks(fulfillHooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](2)
            })
        );
        vm.stopPrank();
    }

    function _depositFreeAssets(
        uint256 allocationAmountVault1,
        uint256 allocationAmountVault2,
        address vault1,
        address vault2,
        bytes4 revertSelector
    )
        internal
    {
        address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        address[] memory fulfillHooksAddresses = new address[](2);
        fulfillHooksAddresses[0] = depositHookAddress;
        fulfillHooksAddresses[1] = depositHookAddress;

        bytes[] memory fulfillHooksData = new bytes[](2);
        // allocate up to the max allocation rate in the two Vaults
        fulfillHooksData[0] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            vault1,
            address(asset),
            allocationAmountVault1,
            false,
            address(0),
            0
        );
        fulfillHooksData[1] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            vault2,
            address(asset),
            allocationAmountVault2,
            false,
            address(0),
            0
        );

        uint256[] memory expectedAssetsOrSharesOut = new uint256[](2);
        expectedAssetsOrSharesOut[0] = IERC4626(address(vault1)).convertToShares(allocationAmountVault1);
        expectedAssetsOrSharesOut[1] = IERC4626(address(vault2)).convertToShares(allocationAmountVault2);

        bytes[] memory argsForProofs = new bytes[](2);
        argsForProofs[0] = ISuperHookInspector(fulfillHooksAddresses[0]).inspect(fulfillHooksData[0]);
        argsForProofs[1] = ISuperHookInspector(fulfillHooksAddresses[1]).inspect(fulfillHooksData[1]);

        vm.startPrank(MANAGER);
        bool revertExpected = revertSelector != bytes4(0);

        if (revertExpected) {
            vm.expectRevert(revertSelector);
            strategy.executeHooks(
                ISuperVaultStrategy.ExecuteArgs({
                    hooks: fulfillHooksAddresses,
                    hookCalldata: fulfillHooksData,
                    expectedAssetsOrSharesOut: expectedAssetsOrSharesOut,
                    globalProofs: _getMerkleProofsForHooks(fulfillHooksAddresses, argsForProofs),
                    strategyProofs: new bytes32[][](2)
                })
            );
        } else {
            strategy.executeHooks(
                ISuperVaultStrategy.ExecuteArgs({
                    hooks: fulfillHooksAddresses,
                    hookCalldata: fulfillHooksData,
                    expectedAssetsOrSharesOut: expectedAssetsOrSharesOut,
                    globalProofs: _getMerkleProofsForHooks(fulfillHooksAddresses, argsForProofs),
                    strategyProofs: new bytes32[][](2)
                })
            );
        }
        vm.stopPrank();
    }

    function _depositFreeAssets(
        uint256 allocationAmountVault1,
        uint256 allocationAmountVault2,
        address vault1,
        address vault2,
        uint256[] memory expectedAssetsOrSharesOut,
        bytes4 revertSelector
    )
        internal
    {
        address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        address[] memory fulfillHooksAddresses = new address[](2);
        fulfillHooksAddresses[0] = depositHookAddress;
        fulfillHooksAddresses[1] = depositHookAddress;

        bytes[] memory fulfillHooksData = new bytes[](2);
        // allocate up to the max allocation rate in the two Vaults
        fulfillHooksData[0] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            vault1,
            address(asset),
            allocationAmountVault1,
            false,
            address(0),
            0
        );
        fulfillHooksData[1] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            vault2,
            address(asset),
            allocationAmountVault2,
            false,
            address(0),
            0
        );

        bytes[] memory argsForProofs = new bytes[](2);
        argsForProofs[0] = ISuperHookInspector(fulfillHooksAddresses[0]).inspect(fulfillHooksData[0]);
        argsForProofs[1] = ISuperHookInspector(fulfillHooksAddresses[1]).inspect(fulfillHooksData[1]);

        vm.startPrank(MANAGER);
        bool revertExpected = revertSelector != bytes4(0);

        if (revertExpected) {
            vm.expectRevert(revertSelector);
            strategy.executeHooks(
                ISuperVaultStrategy.ExecuteArgs({
                    hooks: fulfillHooksAddresses,
                    hookCalldata: fulfillHooksData,
                    expectedAssetsOrSharesOut: expectedAssetsOrSharesOut,
                    globalProofs: _getMerkleProofsForHooks(fulfillHooksAddresses, argsForProofs),
                    strategyProofs: new bytes32[][](2)
                })
            );
        } else {
            strategy.executeHooks(
                ISuperVaultStrategy.ExecuteArgs({
                    hooks: fulfillHooksAddresses,
                    hookCalldata: fulfillHooksData,
                    expectedAssetsOrSharesOut: expectedAssetsOrSharesOut,
                    globalProofs: _getMerkleProofsForHooks(fulfillHooksAddresses, argsForProofs),
                    strategyProofs: new bytes32[][](2)
                })
            );
        }

        vm.stopPrank();
    }

    function _depositFreeAssets(
        address vault1,
        address vault2,
        address vault3,
        uint256 allocationAmountVault1,
        uint256 allocationAmountVault2,
        uint256 allocationAmountVault3
    )
        internal
    {
        DepositFreeAssetsVars memory vars;
        vars.depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);
        vars.yieldSourceOracleId = _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER);
        vars.assetAddress = address(asset);

        vars.fulfillHooksAddresses = new address[](3);
        vars.fulfillHooksAddresses[0] = vars.depositHookAddress;
        vars.fulfillHooksAddresses[1] = vars.depositHookAddress;
        vars.fulfillHooksAddresses[2] = vars.depositHookAddress;

        vars.fulfillHooksData = new bytes[](3);
        // allocate up to the max allocation rate in the three Vaults
        vars.fulfillHooksData[0] = _createApproveAndDeposit4626HookData(
            vars.yieldSourceOracleId, vault1, vars.assetAddress, allocationAmountVault1, false, address(0), 0
        );
        vars.fulfillHooksData[1] = _createApproveAndDeposit4626HookData(
            vars.yieldSourceOracleId, vault2, vars.assetAddress, allocationAmountVault2, false, address(0), 0
        );
        vars.fulfillHooksData[2] = _createApproveAndDeposit4626HookData(
            vars.yieldSourceOracleId, vault3, vars.assetAddress, allocationAmountVault3, false, address(0), 0
        );

        vars.expectedAssetsOrSharesOut = new uint256[](3);
        vars.expectedAssetsOrSharesOut[0] = IERC4626(address(vault1)).convertToShares(allocationAmountVault1);
        vars.expectedAssetsOrSharesOut[1] = IERC4626(address(vault2)).convertToShares(allocationAmountVault2);
        vars.expectedAssetsOrSharesOut[2] = IERC4626(address(vault3)).convertToShares(allocationAmountVault3);

        vm.startPrank(MANAGER);
        vars.argsForProofs = new bytes[](3);
        vars.argsForProofs[0] = ISuperHookInspector(vars.fulfillHooksAddresses[0]).inspect(vars.fulfillHooksData[0]);
        vars.argsForProofs[1] = ISuperHookInspector(vars.fulfillHooksAddresses[1]).inspect(vars.fulfillHooksData[1]);
        vars.argsForProofs[2] = ISuperHookInspector(vars.fulfillHooksAddresses[2]).inspect(vars.fulfillHooksData[2]);

        vars.executeArgs = ISuperVaultStrategy.ExecuteArgs({
            hooks: vars.fulfillHooksAddresses,
            hookCalldata: vars.fulfillHooksData,
            expectedAssetsOrSharesOut: vars.expectedAssetsOrSharesOut,
            globalProofs: _getMerkleProofsForHooks(vars.fulfillHooksAddresses, vars.argsForProofs),
            strategyProofs: new bytes32[][](3)
        });

        strategy.executeHooks(vars.executeArgs);
        vm.stopPrank();
    }

    function _fulfillRedeemForUsers(
        address[] memory requestingUsers,
        uint256 redeemSharesVault1,
        uint256 redeemSharesVault2,
        address vault1,
        address vault2
    )
        internal
    {
        address withdrawHookAddress = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);

        address[] memory fulfillHooksAddresses = new address[](2);
        fulfillHooksAddresses[0] = withdrawHookAddress;
        fulfillHooksAddresses[1] = withdrawHookAddress;

        bytes[] memory fulfillHooksData = new bytes[](2);
        // Withdraw proportionally from both vaults
        fulfillHooksData[0] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            vault1,
            address(strategy),
            redeemSharesVault1,
            false
        );
        fulfillHooksData[1] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            vault2,
            address(strategy),
            redeemSharesVault2,
            false
        );

        uint256[] memory expectedAssetsOrSharesOut = new uint256[](2);
        {
            (uint256 totalSvAssets,) = totalAssetHelper.totalAssets(address(strategy));
            uint256 pricePerShare = totalSvAssets.mulDiv(vault.PRECISION(), vault.totalSupply(), Math.Rounding.Floor);

            uint256 amountForVault1 = redeemSharesVault1 * vault.PRECISION() / pricePerShare;
            uint256 amountForVault2 = redeemSharesVault2 * vault.PRECISION() / pricePerShare;

            uint256 underlyingSharesForVault1 = IERC4626(address(vault1)).convertToShares(amountForVault1);
            uint256 underlyingSharesForVault2 = IERC4626(address(vault2)).convertToShares(amountForVault2);

             uint256 vault1ConvertToAssets = IERC4626(address(vault1)).convertToAssets(underlyingSharesForVault1);
            uint256 vault2ConvertToAssets = IERC4626(address(vault2)).convertToAssets(underlyingSharesForVault2);

            expectedAssetsOrSharesOut[0] = vault1ConvertToAssets - vault1ConvertToAssets * 1e3 / 1e5;
            expectedAssetsOrSharesOut[1] = vault2ConvertToAssets - vault2ConvertToAssets * 1e3 / 1e5;
        }

        vm.startPrank(MANAGER);
        bytes[] memory argsForProofs = new bytes[](2);
        argsForProofs[0] = ISuperHookInspector(fulfillHooksAddresses[0]).inspect(fulfillHooksData[0]);
        argsForProofs[1] = ISuperHookInspector(fulfillHooksAddresses[1]).inspect(fulfillHooksData[1]);

        console2.log("----argsForProofsLength", argsForProofs.length);
        console2.log("----argsForProofs[0]");
        console2.logBytes(argsForProofs[0]);
        console2.log("----argsForProofs[1]");
        console2.logBytes(argsForProofs[1]);

        strategy.fulfillRedeemRequests(
            ISuperVaultStrategy.FulfillArgs({
                controllers: requestingUsers,
                hooks: fulfillHooksAddresses,
                hookCalldata: fulfillHooksData,
                expectedAssetsOrSharesOut: expectedAssetsOrSharesOut,
                globalProofs: _getMerkleProofsForHooks(fulfillHooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](2)
            })
        );
        vm.stopPrank();
    }

    function _fulfillRedeemForUsersAfterAllocation(
        address[] memory requestingUsers,
        uint256 redeemSharesVault1,
        uint256 redeemSharesVault2,
        address vault1,
        address vault2
    )
        internal
    {
        address withdrawHookAddress = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);

        address[] memory fulfillHooksAddresses = new address[](2);
        fulfillHooksAddresses[0] = withdrawHookAddress;
        fulfillHooksAddresses[1] = withdrawHookAddress;

        bytes[] memory fulfillHooksData = new bytes[](2);
        // Withdraw proportionally from both vaults
        fulfillHooksData[0] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            vault1,
            address(strategy),
            redeemSharesVault1,
            false
        );
        fulfillHooksData[1] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            vault2,
            address(strategy),
            redeemSharesVault2,
            false
        );

        uint256[] memory expectedAssetsOrSharesOut = new uint256[](2);
        {
            uint256 pricePerShare = strategy.getStoredPPS();

            uint256 amountForVault1 = redeemSharesVault1 * vault.PRECISION() / pricePerShare;
            uint256 amountForVault2 = redeemSharesVault2 * vault.PRECISION() / pricePerShare;

            uint256 underlyingSharesForVault1 = IERC4626(address(vault1)).convertToShares(amountForVault1);
            uint256 underlyingSharesForVault2 = IERC4626(address(vault2)).convertToShares(amountForVault2);

            expectedAssetsOrSharesOut[0] = IERC4626(address(vault1)).convertToAssets(underlyingSharesForVault1);
            expectedAssetsOrSharesOut[1] = IERC4626(address(vault2)).convertToAssets(underlyingSharesForVault2);
        }

        vm.startPrank(MANAGER);
        bytes[] memory argsForProofs = new bytes[](2);
        argsForProofs[0] = ISuperHookInspector(fulfillHooksAddresses[0]).inspect(fulfillHooksData[0]);
        argsForProofs[1] = ISuperHookInspector(fulfillHooksAddresses[1]).inspect(fulfillHooksData[1]);

        console2.log("----argsForProofsLength", argsForProofs.length);
        console2.log("----argsForProofs[0]");
        console2.logBytes(argsForProofs[0]);
        console2.log("----argsForProofs[1]");
        console2.logBytes(argsForProofs[1]);

        strategy.fulfillRedeemRequests(
            ISuperVaultStrategy.FulfillArgs({
                controllers: requestingUsers,
                hooks: fulfillHooksAddresses,
                hookCalldata: fulfillHooksData,
                expectedAssetsOrSharesOut: expectedAssetsOrSharesOut,
                globalProofs: _getMerkleProofsForHooks(fulfillHooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](2)
            })
        );
        vm.stopPrank();
    }

    function _fulfillRedeemForUsers(
        address[] memory requestingUsers,
        uint256 redeemSharesVault1,
        uint256 redeemSharesVault2,
        address vault1,
        address vault2,
        uint256[] memory expectedAssetsOrSharesOut,
        bytes4 revertSelector
    )
        internal
    {
        for (uint256 i; i < expectedAssetsOrSharesOut.length; i++) {
            expectedAssetsOrSharesOut[i] = expectedAssetsOrSharesOut[i] - expectedAssetsOrSharesOut[i] * 1e3 / 1e5;
        }
        address withdrawHookAddress = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);

        address[] memory fulfillHooksAddresses = new address[](2);
        fulfillHooksAddresses[0] = withdrawHookAddress;
        fulfillHooksAddresses[1] = withdrawHookAddress;

        bytes[] memory fulfillHooksData = new bytes[](2);
        // Withdraw proportionally from both vaults
        fulfillHooksData[0] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            vault1,
            address(strategy),
            redeemSharesVault1,
            false
        );
        fulfillHooksData[1] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            vault2,
            address(strategy),
            redeemSharesVault2,
            false
        );
        bytes[] memory argsForProofs = new bytes[](2);
        argsForProofs[0] = ISuperHookInspector(fulfillHooksAddresses[0]).inspect(fulfillHooksData[0]);
        argsForProofs[1] = ISuperHookInspector(fulfillHooksAddresses[1]).inspect(fulfillHooksData[1]);

        bytes32[][] memory proofs = _getMerkleProofsForHooks(fulfillHooksAddresses, argsForProofs);
        vm.startPrank(MANAGER);
        if (revertSelector != bytes4(0)) {
            vm.expectRevert(revertSelector);
        }

        strategy.fulfillRedeemRequests(
            ISuperVaultStrategy.FulfillArgs({
                controllers: requestingUsers,
                hooks: fulfillHooksAddresses,
                hookCalldata: fulfillHooksData,
                expectedAssetsOrSharesOut: expectedAssetsOrSharesOut,
                globalProofs: proofs,
                strategyProofs: new bytes32[][](2)
            })
        );
        vm.stopPrank();
    }

    // Local variables struct for _fulfillRedeem
    struct FulfillRedeem7540UnderlyingLocalVars {
        address[] requestingUsers;
        address[] fulfillHooksAddresses;
        uint256 centrifugeSharesOut;
        uint256 aaveSharesOut;
        bytes[] fulfillHooksData;
        uint256 totalSvAssets;
        uint256 pricePerShare;
        uint256 amountForAave;
        uint256 amountForCentrifuge;
        uint256 underlyingSharesForAave;
        uint256 underlyingSharesForCentrifuge;
        uint256[] expectedAssetsOrSharesOut;
    }

    /**
     * @notice Fulfills a redeem request from both underlying vaults
     * @param redeemShares The number of shares to redeem
     * @param vault1 The address of the first vault (4626 vault)
     * @param vault2 The address of the second vault (7540 vault)
     */
    function _fulfillRedeem7540Underlying(
        uint256 redeemShares,
        address vault1,
        address vault2,
        address account
    )
        internal
    {
        FulfillRedeem7540UnderlyingLocalVars memory vars;

        vars.requestingUsers = new address[](1);
        vars.requestingUsers[0] = account;

        vars.fulfillHooksAddresses = new address[](2);
        vars.fulfillHooksAddresses[0] = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);
        vars.fulfillHooksAddresses[1] = _getHookAddress(ETH, REDEEM_7540_VAULT_HOOK_KEY);

        (vars.aaveSharesOut, vars.centrifugeSharesOut) =
            _calculateVaultShares7540Underlying(redeemShares, vault1, vault2);

        uint256 aaveShares = IERC4626(address(vault1)).balanceOf(address(strategy));
        uint256 centrifugeShares = IERC20Metadata(centrifugeVault.share()).balanceOf(address(strategy));
        _requestRedeemFrom7540Underlying(centrifugeShares, vault2);

        vars.fulfillHooksData = new bytes[](2);
        vars.fulfillHooksData[0] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            vault1,
            address(strategy),
            vars.aaveSharesOut,
            false
        );

        vars.fulfillHooksData[1] = _createRedeem7540VaultHookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC7540_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            vault2,
            vars.centrifugeSharesOut,
            false
        );

        (vars.totalSvAssets,) = totalAssetHelper.totalAssets(address(strategy));
        vars.pricePerShare = vars.totalSvAssets.mulDiv(strategy.PRECISION(), vault.totalSupply(), Math.Rounding.Floor);

        vars.expectedAssetsOrSharesOut = new uint256[](2);
        vars.expectedAssetsOrSharesOut[0] = IERC4626(address(vault1)).convertToAssets(aaveShares);
        vars.expectedAssetsOrSharesOut[1] = centrifugeVault.convertToAssets(centrifugeShares);

        for (uint256 i; i < vars.expectedAssetsOrSharesOut.length; i++) {
            vars.expectedAssetsOrSharesOut[i] = vars.expectedAssetsOrSharesOut[i] - vars.expectedAssetsOrSharesOut[i] * 1e3 / 1e5;
        }

        vm.startPrank(MANAGER);
        bytes[] memory argsForProofs = new bytes[](2);
        argsForProofs[0] = ISuperHookInspector(vars.fulfillHooksAddresses[0]).inspect(vars.fulfillHooksData[0]);
        argsForProofs[1] = ISuperHookInspector(vars.fulfillHooksAddresses[1]).inspect(vars.fulfillHooksData[1]);

        strategy.fulfillRedeemRequests(
            ISuperVaultStrategy.FulfillArgs({
                controllers: vars.requestingUsers,
                hooks: vars.fulfillHooksAddresses,
                hookCalldata: vars.fulfillHooksData,
                expectedAssetsOrSharesOut: vars.expectedAssetsOrSharesOut,
                globalProofs: _getMerkleProofsForHooks(vars.fulfillHooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](2)
            })
        );
        vm.stopPrank();
    }

    /**
     * @notice Requests a redeem from the 7540 vault and fulfills the request as Centrifuge
     * @param redeemShares The number of shares to redeem
     * @param vault7540 The address of the 7540 vault
     */
    function _requestRedeemFrom7540Underlying(uint256 redeemShares, address vault7540) internal {
        address[] memory hooksAddresses = new address[](1);
        hooksAddresses[0] = _getHookAddress(ETH, REQUEST_REDEEM_7540_VAULT_HOOK_KEY);

        bytes[] memory hooksData = new bytes[](1);
        hooksData[0] = _createRequestRedeem7540VaultHookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC7540_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            vault7540,
            redeemShares,
            false
        );

        console2.log("__requestRedeemFrom7540Underlying ------ redeemShares", redeemShares);

        uint256[] memory expectedAssetsOrSharesOut = new uint256[](1);
        expectedAssetsOrSharesOut[0] = 0;

        bytes[] memory argsForProofs = new bytes[](1);
        argsForProofs[0] = ISuperHookInspector(hooksAddresses[0]).inspect(hooksData[0]);

        vm.startPrank(MANAGER);
        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooksAddresses,
                hookCalldata: hooksData,
                expectedAssetsOrSharesOut: expectedAssetsOrSharesOut,
                globalProofs: _getMerkleProofsForHooks(hooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](1)
            })
        );
        vm.stopPrank();

        uint256 expectedAssets = IERC7540(address(vault7540)).convertToAssets(redeemShares);

        vm.prank(rootManager);
        investmentManager.fulfillRedeemRequest(
            poolId, trancheId, address(strategy), assetId, uint128(expectedAssets), uint128(redeemShares)
        );
    }

    function _completeDepositFlow(uint256 depositAmount) internal {
        // create deposit requests for all users
        _depositForAllUsers(depositAmount);

        // create fullfillment data
        uint256 totalAmount = depositAmount * ACCOUNT_COUNT;
        uint256 allocationAmountVault1 = totalAmount / 2;
        uint256 allocationAmountVault2 = totalAmount - allocationAmountVault1;

        // fulfill deposits
        _depositFreeAssets(allocationAmountVault1, allocationAmountVault2, address(fluidVault), address(aaveVault));
    }

    function _completeDepositFlowWithVaryingAmounts(uint256[] memory depositAmounts) internal {
        require(depositAmounts.length == ACCOUNT_COUNT, "Invalid deposit amounts length");

        // Calculate total amount for allocation
        uint256 totalAmount;
        for (uint256 i; i < ACCOUNT_COUNT; ++i) {
            _getTokens(address(asset), accInstances[i].account, depositAmounts[i]);
            _depositForAccount(accInstances[i], depositAmounts[i]);
            totalAmount += depositAmounts[i];
        }

        // create fullfillment data
        uint256 allocationAmountVault1 = totalAmount / 2;
        uint256 allocationAmountVault2 = totalAmount - allocationAmountVault1;

        // fulfill deposits
        _depositFreeAssets(allocationAmountVault1, allocationAmountVault2, address(fluidVault), address(aaveVault));
    }

    /**
     * @notice Struct to hold local variables for the _reallocate function
     */
    struct ReallocateLocalVars {
        // Current balances
        uint256 currentVault1Balance;
        uint256 currentVault2Balance;
        uint256 currentVault3Balance;
        uint256 totalBalance;
        // Target balances
        uint256 targetVault1Assets;
        uint256 targetVault2Assets;
        uint256 targetVault3Assets;
        // Differences
        int256 vault1Diff;
        int256 vault2Diff;
        int256 vault3Diff;
        // Sources and destinations
        address[] sources;
        uint256[] sourceAmounts;
        address[] destinations;
        uint256[] destinationAmounts;
        uint256 sourceCount;
        uint256 destCount;
        // For moving assets
        address source;
        address destination;
        uint256 amountToMove;
        uint256 sharesToRedeem;
        address[] hooksAddresses;
        bytes[] hooksData;
        // Final balances and ratios
        uint256 finalVault1Balance;
        uint256 finalVault2Balance;
        uint256 finalVault3Balance;
        uint256 totalFinalBalance;
        uint256 finalVault1Ratio;
        uint256 finalVault2Ratio;
        uint256 finalVault3Ratio;
    }

    /**
     * @notice Struct to hold arguments for the _reallocate function
     */
    struct ReallocateArgs {
        IERC4626 vault1;
        IERC4626 vault2;
        IERC4626 vault3;
        uint256 targetVault1Percentage;
        uint256 targetVault2Percentage;
        uint256 targetVault3Percentage;
        address withdrawHookAddress;
        address depositHookAddress;
    }

    function _reallocate(ReallocateArgs memory args)
        internal
        returns (uint256, uint256, uint256, uint256, uint256, uint256)
    {
        ReallocateLocalVars memory vars;

        // Get current balances
        vars.currentVault1Balance = args.vault1.convertToAssets(args.vault1.balanceOf(address(strategy)));
        vars.currentVault2Balance = args.vault2.convertToAssets(args.vault2.balanceOf(address(strategy)));
        vars.currentVault3Balance = args.vault3.convertToAssets(args.vault3.balanceOf(address(strategy)));

        vars.totalBalance = vars.currentVault1Balance + vars.currentVault2Balance + vars.currentVault3Balance;

        // Calculate target balances based on percentages (in basis points)
        vars.targetVault1Assets = vars.totalBalance * args.targetVault1Percentage / 10_000;
        vars.targetVault2Assets = vars.totalBalance * args.targetVault2Percentage / 10_000;
        vars.targetVault3Assets = vars.totalBalance * args.targetVault3Percentage / 10_000;

        console2.log("Total balance:", vars.totalBalance);
        console2.log("Target Vault1 Assets:", vars.targetVault1Assets);
        console2.log("Target Vault2 Assets:", vars.targetVault2Assets);
        console2.log("Target Vault3 Assets:", vars.targetVault3Assets);

        // Calculate the differences between current and target allocations
        vars.vault1Diff = int256(vars.targetVault1Assets) - int256(vars.currentVault1Balance);
        vars.vault2Diff = int256(vars.targetVault2Assets) - int256(vars.currentVault2Balance);
        vars.vault3Diff = int256(vars.targetVault3Assets) - int256(vars.currentVault3Balance);

        console2.log("\n=== Allocation Differences ===");
        console2.log("Vault1 Diff:", vars.vault1Diff);
        console2.log("Vault2 Diff:", vars.vault2Diff);
        console2.log("Vault3 Diff:", vars.vault3Diff);

        // Identify sources (vaults with excess assets) and destinations (vaults needing assets)
        vars.sources = new address[](3);
        vars.sourceAmounts = new uint256[](3);
        vars.destinations = new address[](3);
        vars.destinationAmounts = new uint256[](3);
        vars.sourceCount = 0;
        vars.destCount = 0;

        if (vars.vault1Diff < 0) {
            vars.sources[vars.sourceCount] = address(args.vault1);
            vars.sourceAmounts[vars.sourceCount] = uint256(-vars.vault1Diff);
            vars.sourceCount++;
        } else if (vars.vault1Diff > 0) {
            vars.destinations[vars.destCount] = address(args.vault1);
            vars.destinationAmounts[vars.destCount] = uint256(vars.vault1Diff);
            vars.destCount++;
        }

        if (vars.vault2Diff < 0) {
            vars.sources[vars.sourceCount] = address(args.vault2);
            vars.sourceAmounts[vars.sourceCount] = uint256(-vars.vault2Diff);
            vars.sourceCount++;
        } else if (vars.vault2Diff > 0) {
            vars.destinations[vars.destCount] = address(args.vault2);
            vars.destinationAmounts[vars.destCount] = uint256(vars.vault2Diff);
            vars.destCount++;
        }

        if (vars.vault3Diff < 0) {
            vars.sources[vars.sourceCount] = address(args.vault3);
            vars.sourceAmounts[vars.sourceCount] = uint256(-vars.vault3Diff);
            vars.sourceCount++;
        } else if (vars.vault3Diff > 0) {
            vars.destinations[vars.destCount] = address(args.vault3);
            vars.destinationAmounts[vars.destCount] = uint256(vars.vault3Diff);
            vars.destCount++;
        }

        // Resize arrays to actual count
        vars.sources = _resizeAddressArray(vars.sources, vars.sourceCount);
        vars.sourceAmounts = _resizeUint256Array(vars.sourceAmounts, vars.sourceCount);
        vars.destinations = _resizeAddressArray(vars.destinations, vars.destCount);
        vars.destinationAmounts = _resizeUint256Array(vars.destinationAmounts, vars.destCount);

        console2.log("\n=== Sources and Destinations ===");
        for (uint256 i = 0; i < vars.sourceCount; i++) {
            console2.log("Source:", vars.sources[i]);
            console2.log("Amount:", vars.sourceAmounts[i]);
        }
        for (uint256 i = 0; i < vars.destCount; i++) {
            console2.log("Destination:", vars.destinations[i]);
            console2.log("Amount:", vars.destinationAmounts[i]);
        }

        // Create a single array of all transfers (source to destination)
        // Each transfer requires 2 hooks: withdraw and deposit
        uint256 maxTransfers = vars.sourceCount * vars.destCount;
        address[] memory allHooksAddresses = new address[](maxTransfers * 2);
        bytes[] memory allHooksData = new bytes[](maxTransfers * 2);
        uint256[] memory expectedAssetsOrSharesOut = new uint256[](maxTransfers * 2);
        bytes[] memory argsForProofs = new bytes[](maxTransfers * 2);
        uint256 hookIndex = 0;

        // Create a matrix of transfers from sources to destinations
        for (uint256 i = 0; i < vars.sourceCount; i++) {
            for (uint256 j = 0; j < vars.destCount; j++) {
                if (vars.sourceAmounts[i] > 0 && vars.destinationAmounts[j] > 0) {
                    vars.amountToMove = vars.sourceAmounts[i] < vars.destinationAmounts[j]
                        ? vars.sourceAmounts[i]
                        : vars.destinationAmounts[j];

                    if (vars.amountToMove > 0) {
                        console2.log("\nMoving", vars.amountToMove);
                        console2.log("from", vars.sources[i], "to", vars.destinations[j]);

                        // Convert asset amount to shares for the source vault
                        if (vars.sources[i] == address(args.vault1)) {
                            vars.sharesToRedeem = args.vault1.convertToShares(vars.amountToMove);
                        } else if (vars.sources[i] == address(args.vault2)) {
                            vars.sharesToRedeem = args.vault2.convertToShares(vars.amountToMove);
                        } else if (vars.sources[i] == address(args.vault3)) {
                            vars.sharesToRedeem = args.vault3.convertToShares(vars.amountToMove);
                        }

                        console2.log("Shares to redeem:", vars.sharesToRedeem);

                        // Add withdraw hook
                        allHooksAddresses[hookIndex] = args.withdrawHookAddress;
                        allHooksData[hookIndex] = _createRedeem4626HookData(
                            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
                            vars.sources[i],
                            address(strategy),
                            vars.sharesToRedeem,
                            false
                        );
                        expectedAssetsOrSharesOut[hookIndex] =
                            IERC4626(vars.sources[i]).previewRedeem(vars.sharesToRedeem);
                        argsForProofs[hookIndex] =
                            ISuperHookInspector(allHooksAddresses[hookIndex]).inspect(allHooksData[hookIndex]);
                        hookIndex++;

                        // Add deposit hook
                        allHooksAddresses[hookIndex] = args.depositHookAddress;
                        allHooksData[hookIndex] = _createApproveAndDeposit4626HookData(
                            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
                            vars.destinations[j],
                            address(asset),
                            vars.amountToMove,
                            true,
                            address(0),
                            0
                        );
                        expectedAssetsOrSharesOut[hookIndex] =
                            IERC4626(vars.sources[i]).previewDeposit(vars.amountToMove);
                        argsForProofs[hookIndex] =
                            ISuperHookInspector(allHooksAddresses[hookIndex]).inspect(allHooksData[hookIndex]);
                        hookIndex++;

                        // Update remaining amounts
                        vars.sourceAmounts[i] -= vars.amountToMove;
                        vars.destinationAmounts[j] -= vars.amountToMove;

                        // If source is depleted, break inner loop and move to next source
                        if (vars.sourceAmounts[i] == 0) {
                            break;
                        }
                    }
                }
            }
        }

        // Resize hook arrays to actual count
        if (hookIndex > 0) {
            address[] memory finalHooksAddresses = new address[](hookIndex);
            bytes[] memory finalHooksData = new bytes[](hookIndex);
            uint256[] memory finalExpectedAssetsOrSharesOut = new uint256[](hookIndex);
            bytes[] memory finalArgsForProofs = new bytes[](hookIndex);
            for (uint256 i = 0; i < hookIndex; i++) {
                finalHooksAddresses[i] = allHooksAddresses[i];
                finalHooksData[i] = allHooksData[i];
                finalExpectedAssetsOrSharesOut[i] = expectedAssetsOrSharesOut[i];
                finalArgsForProofs[i] = argsForProofs[i];
            }

            // Execute all hooks in a single transaction
            vm.startPrank(MANAGER);

            strategy.executeHooks(
                ISuperVaultStrategy.ExecuteArgs({
                    hooks: finalHooksAddresses,
                    hookCalldata: finalHooksData,
                    expectedAssetsOrSharesOut: finalExpectedAssetsOrSharesOut,
                    globalProofs: _getMerkleProofsForHooks(finalHooksAddresses, finalArgsForProofs),
                    strategyProofs: new bytes32[][](finalHooksAddresses.length)
                })
            );
            vm.stopPrank();
        }

        // Check new balances after reallocation
        vars.finalVault1Balance = args.vault1.convertToAssets(args.vault1.balanceOf(address(strategy)));
        vars.finalVault2Balance = args.vault2.convertToAssets(args.vault2.balanceOf(address(strategy)));
        vars.finalVault3Balance = args.vault3.convertToAssets(args.vault3.balanceOf(address(strategy)));

        console2.log("\n=== Final Balances After Reallocation ===");
        console2.log("Final Vault1 balance:", vars.finalVault1Balance);
        console2.log("Final Vault2 balance:", vars.finalVault2Balance);
        console2.log("Final Vault3 balance:", vars.finalVault3Balance);

        // Calculate final allocation percentages
        vars.totalFinalBalance = vars.finalVault1Balance + vars.finalVault2Balance + vars.finalVault3Balance;
        vars.finalVault1Ratio = (vars.finalVault1Balance * 10_000) / vars.totalFinalBalance;
        vars.finalVault2Ratio = (vars.finalVault2Balance * 10_000) / vars.totalFinalBalance;
        vars.finalVault3Ratio = (vars.finalVault3Balance * 10_000) / vars.totalFinalBalance;

        console2.log("\n=== Final Allocation Ratios ===");
        console2.log("Vault1:", vars.finalVault1Ratio / 100, "%");
        console2.log("Vault2:", vars.finalVault2Ratio / 100, "%");
        console2.log("Vault3:", vars.finalVault3Ratio / 100, "%");

        return (
            vars.finalVault1Balance,
            vars.finalVault2Balance,
            vars.finalVault3Balance,
            vars.finalVault1Ratio,
            vars.finalVault2Ratio,
            vars.finalVault3Ratio
        );
    }

    struct DepositVerificationVars {
        uint256 depositAmount;
        uint256 totalAmount;
        uint256 allocationAmountVault1;
        uint256 allocationAmountVault2;
        uint256 initialFluidVaultBalance;
        uint256 initialAaveVaultBalance;
        uint256 initialStrategyAssetBalance;
        uint256 fluidVaultSharesIncrease;
        uint256 aaveVaultSharesIncrease;
        uint256 strategyAssetBalanceDecrease;
        uint256 fluidVaultAssetsValue;
        uint256 aaveVaultAssetsValue;
        uint256 totalAssetsAllocated;
        uint256 totalSharesMinted;
        uint256 totalAssetsFromShares;
    }

    struct ChangingAllocationVars {
        uint256 firstDepositAmount;
        uint256 secondDepositAmount;
        uint256 firstAllocationVault1;
        uint256 firstAllocationVault2;
        uint256 secondAllocationVault1;
        uint256 secondAllocationVault2;
        uint256 initialShareBalance;
        uint256 firstDepositShares;
        uint256 firstDepositSharePrice;
        uint256 shareBalanceAfterFirstDeposit;
        uint256 secondDepositShares;
        uint256 secondDepositSharePrice;
        uint256 totalShares;
        uint256 totalShareValue;
    }

    function _verifyAndLogChangingAllocation(ChangingAllocationVars memory vars) internal view {
        vars.totalShares = vault.balanceOf(accInstances[0].account) - vars.initialShareBalance;
        assertEq(vars.totalShares, vars.firstDepositShares + vars.secondDepositShares);

        vars.totalShareValue = vault.convertToAssets(vars.totalShares);
        assertApproxEqRel(vars.totalShareValue, vars.firstDepositAmount + vars.secondDepositAmount, 0.01e18); // 1%
            // tolerance

        console2.log(
            "first deposit - vault1 allocation:", vars.firstAllocationVault1 * 100 / vars.firstDepositAmount, "%"
        );
        console2.log(
            "first deposit - vault2 allocation:", vars.firstAllocationVault2 * 100 / vars.firstDepositAmount, "%"
        );
        console2.log("first deposit share price:", vars.firstDepositSharePrice);

        console2.log(
            "second deposit - vault1 allocation:", vars.secondAllocationVault1 * 100 / vars.secondDepositAmount, "%"
        );
        console2.log(
            "second deposit - vault2 allocation:", vars.secondAllocationVault2 * 100 / vars.secondDepositAmount, "%"
        );
        console2.log("second deposit share price:", vars.secondDepositSharePrice);

        console2.log(
            "share price difference percentage:",
            (vars.firstDepositSharePrice > vars.secondDepositSharePrice)
                ? ((vars.firstDepositSharePrice - vars.secondDepositSharePrice) * 100 / vars.firstDepositSharePrice)
                : ((vars.secondDepositSharePrice - vars.firstDepositSharePrice) * 100 / vars.firstDepositSharePrice)
        );
    }

    struct RedeemVerificationVars {
        uint256 depositAmount;
        uint256 redeemAmount;
        uint256 totalDepositAmount;
        uint256 totalRedeemAmount;
        uint256 totalRedeemedAssets;
        uint256 allocationAmountVault1;
        uint256 allocationAmountVault2;
        uint256 initialFluidVaultBalance;
        uint256 initialAaveVaultBalance;
        uint256 initialStrategyAssetBalance;
        uint256 fluidVaultSharesDecrease;
        uint256 aaveVaultSharesDecrease;
        uint256 strategyAssetBalanceIncrease;
        uint256 fluidVaultAssetsValue;
        uint256 aaveVaultAssetsValue;
        uint256 totalAssetsRedeemed;
        uint256 totalSharesBurned;
        uint256[] userShareBalances;
    }

    function _verifyRedeemSharesAndAssets(RedeemVerificationVars memory vars) internal {
        uint256[] memory initialAssetBalances = new uint256[](ACCOUNT_COUNT);
        vars.totalSharesBurned = 0;

        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            initialAssetBalances[i] = asset.balanceOf(accInstances[i].account);
        }
        uint256 totalAssetsReceived = 0;
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            uint256 claimableWithdraw = vault.maxWithdraw(accInstances[i].account);
            console2.log("claimable withdraw:", claimableWithdraw);
            _claimWithdrawForAccount(accInstances[i], claimableWithdraw);

            uint256 sharesBurned = vars.userShareBalances[i] - vault.balanceOf(accInstances[i].account);
            vars.totalSharesBurned += sharesBurned;

            uint256 assetsReceived = asset.balanceOf(accInstances[i].account) - initialAssetBalances[i];
            totalAssetsReceived += assetsReceived;
            console2.log("\n---");
            console2.log("assets received:", assetsReceived);
            /// @dev a deviation exists here because of the averageWithdrawPrice
            assertApproxEqRel(assetsReceived, claimableWithdraw, 0.001e18);

            uint256 remainingShares = vault.balanceOf(accInstances[i].account);
            uint256 remainingSharesValue = vault.convertToAssets(remainingShares);
            assertApproxEqRel(remainingSharesValue, vars.depositAmount - claimableWithdraw, 0.01e18);
        }

        uint256 assetsFromTotalSharesBurned = vault.convertToAssets(vars.totalSharesBurned);
        assertApproxEqRel(assetsFromTotalSharesBurned, totalAssetsReceived, 0.01e18);
    }

    function _setFeeConfig(uint256 feePercent, address feeRecipient) internal {
        vm.startPrank(MANAGER);
        strategy.proposeVaultFeeConfigUpdate(feePercent, 0, feeRecipient);
        vm.warp(block.timestamp + 1 weeks);
        strategy.executeVaultFeeConfigUpdate();
        vm.stopPrank();
    }

    function _setFeeConfig(uint256 performanceFeeBps, uint256 managementFeeBps, address feeRecipient) internal {
        vm.startPrank(MANAGER);
        strategy.proposeVaultFeeConfigUpdate(performanceFeeBps, managementFeeBps, feeRecipient);
        vm.warp(block.timestamp + 1 weeks);
        strategy.executeVaultFeeConfigUpdate();
        vm.stopPrank();
    }

    function _rebalanceFixedAmountFromVaultToVault(
        address[] memory hooksAddresses,
        bytes[] memory hooksData,
        address sourceVault,
        address targetVault,
        uint256 assetsToMove
    )
        internal
    {
        uint256 sharesToRedeem = IERC4626(sourceVault).convertToShares(assetsToMove);

        vm.startPrank(MANAGER);
        hooksData[0] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            sourceVault,
            address(strategy),
            sharesToRedeem,
            false
        );
        hooksData[1] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            targetVault,
            address(asset),
            assetsToMove,
            true,
            address(0),
            0
        );

        uint256[] memory expectedAssetsOrSharesOut = new uint256[](2);
        expectedAssetsOrSharesOut[0] = 0;
        expectedAssetsOrSharesOut[1] = IERC4626(sourceVault).previewRedeem(sharesToRedeem);
        bytes[] memory argsForProofs = new bytes[](2);
        argsForProofs[0] = ISuperHookInspector(hooksAddresses[0]).inspect(hooksData[0]);
        argsForProofs[1] = ISuperHookInspector(hooksAddresses[1]).inspect(hooksData[1]);

        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooksAddresses,
                hookCalldata: hooksData,
                expectedAssetsOrSharesOut: expectedAssetsOrSharesOut,
                globalProofs: _getMerkleProofsForHooks(hooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](hooksAddresses.length)
            })
        );
        vm.stopPrank();
    }

    function _rebalanceFromVaultToVault(
        address[] memory hooksAddresses,
        bytes[] memory hooksData,
        address sourceVault,
        address targetVault,
        uint256 targetAssets,
        uint256 currentAssets
    )
        internal
    {
        uint256 assetsToMove = targetAssets - currentAssets;
        uint256 sharesToRedeem = IERC4626(sourceVault).convertToShares(assetsToMove);

        vm.startPrank(MANAGER);
        hooksData[0] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            sourceVault,
            address(strategy),
            sharesToRedeem,
            false
        );
        hooksData[1] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY)), MANAGER),
            targetVault,
            address(asset),
            assetsToMove,
            true,
            address(0),
            0
        );

        uint256[] memory expectedAssetsOrSharesOut = new uint256[](2);
        expectedAssetsOrSharesOut[0] = IERC4626(sourceVault).previewRedeem(sharesToRedeem);
        expectedAssetsOrSharesOut[1] = IERC4626(targetVault).previewDeposit(assetsToMove);

        for (uint256 i; i < expectedAssetsOrSharesOut.length; i++) {
            expectedAssetsOrSharesOut[i] = expectedAssetsOrSharesOut[i] - expectedAssetsOrSharesOut[i] * 1e3 / 1e5;
        }
        bytes[] memory argsForProofs = new bytes[](2);
        argsForProofs[0] = ISuperHookInspector(hooksAddresses[0]).inspect(hooksData[0]);
        argsForProofs[1] = ISuperHookInspector(hooksAddresses[1]).inspect(hooksData[1]);

        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooksAddresses,
                hookCalldata: hooksData,
                expectedAssetsOrSharesOut: expectedAssetsOrSharesOut,
                globalProofs: _getMerkleProofsForHooks(hooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](hooksAddresses.length)
            })
        );
        vm.stopPrank();
    }

    // Update function to track deposits
    function _trackDeposit(address user, uint256 shares, uint256 assets) internal {
        SuperVaultState storage state = superVaultStates[user];
        state.accumulatorShares += shares;
        state.accumulatorCostBasis += assets;
    }

    function _deriveSuperVaultFeesFromAssets(
        uint256 currentAssets,
        uint256 historicalAssets
    )
        internal
        view
        returns (uint256, uint256)
    {
        uint256 superformFee;
        uint256 recipientFee;

        SuperVaultStrategy.FeeConfig memory feeConfig = strategy.getConfigInfo();

        if (currentAssets > historicalAssets) {
            uint256 profit = currentAssets - historicalAssets;
            uint256 performanceFeeBps = feeConfig.performanceFeeBps;
            uint256 totalFee = profit.mulDiv(performanceFeeBps, BPS_PRECISION, Math.Rounding.Ceil);

            if (totalFee > 0) {
                uint256 superVaultFeePercent = superGovernor.getFee(FeeType.SUPER_VAULT_PERFORMANCE_FEE);
                // Calculate Superform's portion of the fee
                superformFee = totalFee.mulDiv(superVaultFeePercent, BPS_PRECISION, Math.Rounding.Floor);
                recipientFee = totalFee - superformFee;
            }
        }
        return (superformFee, recipientFee);
    }

    function _getSuperVaultPricePerShare() internal view returns (uint256 pricePerShare) {
        uint256 totalSupplyAmount = vault.totalSupply();
        if (totalSupplyAmount == 0) {
            // For first deposit, set initial PPS to 1 unit in price decimals
            pricePerShare = vault.PRECISION();
        } else {
            // Calculate current PPS in price decimals
            (uint256 totalAssetsVault,) = totalAssetHelper.totalAssets(address(strategy));
            pricePerShare = totalAssetsVault.mulDiv(vault.PRECISION(), totalSupplyAmount, Math.Rounding.Floor);
        }
    }

    /**
     * @notice Structure to hold local variables for the _updateSuperVaultPPS function
     * @dev This helps reduce stack depth issues and organize parameters
     */
    struct UpdatePPSVars {
        uint256 totalSupplyAmount;
        uint256 currentTotalAssets;
        uint256 precision;
        uint256 pps;
        uint256 ppsStdev;
        uint256 validatorSet;
        uint256 totalValidators;
        uint256 timestamp;
        bytes32 messageHash;
        bytes32 ethSignedMessageHash;
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes signature;
        bytes[] proofs;
    }

    /**
     * @notice Updates the PPS (Price Per Share) using TotalAssetHelper
     * @return pps The calculated and updated price per share value
     * @dev This function uses TotalAssetHelper to get totalAssets, calculates PPS,
     *      creates a signature, and updates the PPS through the ECDSAPPSOracle contract
     */
    function _updateSuperVaultPPS(address strategyAddr, address vault_) internal returns (uint256 pps) {
        UpdatePPSVars memory vars;

        vars.totalSupplyAmount = SuperVault(vault_).totalSupply();

        // Get current totalAssets from TotalAssetHelper
        (vars.currentTotalAssets,) = totalAssetHelper.totalAssets(strategyAddr);
        vars.precision = SuperVault(vault_).PRECISION();

        // Calculate price per share based on current totalAssets and totalSupply
        if (vars.totalSupplyAmount == 0) {
            // For first deposit, set initial PPS to 1 unit in price decimals
            vars.pps = vars.precision;
        } else {
            // Calculate current PPS in price decimals using total assets from helper
            vars.pps = vars.currentTotalAssets.mulDiv(vars.precision, vars.totalSupplyAmount, Math.Rounding.Floor);
        }

        // Get the current timestamp for the signature
        vars.timestamp = block.timestamp;

        // Set the additional parameters as requested: ppsStdev=0, validatorSet=1, totalValidators=1
        vars.ppsStdev = 0;
        vars.validatorSet = 1;
        vars.totalValidators = 1;

        // Create the message hash with all parameters
        bytes32 structHash = keccak256(
            abi.encodePacked(
                ecdsappsOracle.UPDATE_PPS_TYPEHASH(),
                strategyAddr,
                vars.pps,
                vars.ppsStdev,
                vars.validatorSet,
                vars.totalValidators,
                vars.timestamp,
                ecdsappsOracle.noncePerStrategy(strategyAddr)
            )
        );
        vars.ethSignedMessageHash = MessageHashUtils.toTypedDataHash(ecdsappsOracle.domainSeparator(), structHash);

        // Create signature (r, s, v) components using the constant KEEPER address
        (vars.v, vars.r, vars.s) = vm.sign(VALIDATOR_KEY, vars.ethSignedMessageHash);

        // Combine the signature components into a single bytes signature
        vars.signature = abi.encodePacked(vars.r, vars.s, vars.v);

        // Create an array of proofs with the signature
        vars.proofs = new bytes[](1);
        vars.proofs[0] = vars.signature;

        // Call batchUpdatePPS on the ECDSAPPSOracle with a single entry
        address[] memory strategies = new address[](1);
        strategies[0] = strategyAddr;
        
        bytes[][] memory proofsArray = new bytes[][](1);
        proofsArray[0] = vars.proofs;
        
        uint256[] memory ppss = new uint256[](1);
        ppss[0] = vars.pps;
        
        uint256[] memory ppsStdevs = new uint256[](1);
        ppsStdevs[0] = vars.ppsStdev;
        
        uint256[] memory validatorSets = new uint256[](1);
        validatorSets[0] = vars.validatorSet;
        
        uint256[] memory totalValidators = new uint256[](1);
        totalValidators[0] = vars.totalValidators;
        
        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = vars.timestamp;

        ecdsappsOracle.updatePPS(
            IECDSAPPSOracle.UpdatePPSArgs({
                strategies: strategies,
                proofsArray: proofsArray,
                ppss: ppss,
                ppsStdevs: ppsStdevs,
                validatorSets: validatorSets,
                totalValidators: totalValidators,
                timestamps: timestamps
            })
        );

        // Log the updated PPS for debugging
        console2.log("Updated PPS for strategy", strategyAddr, vars.pps);

        // Return the calculated PPS value
        pps = vars.pps;
        return pps;
    }

    function _calculateVaultShares(uint256 redeemShares)
        internal
        view
        returns (uint256 fluidSharesOut, uint256 aaveSharesOut)
    {
        // Get current shares in each vault
        uint256 fluidShares = fluidVault.balanceOf(address(strategy));
        uint256 aaveShares = aaveVault.balanceOf(address(strategy));

        // Convert shares to underlying asset values
        uint256 fluidUsdcValue = fluidVault.convertToAssets(fluidShares);
        uint256 aaveUsdcValue = aaveVault.convertToAssets(aaveShares);

        console2.log("fluidUsdcValue", fluidUsdcValue);
        console2.log("aaveUsdcValue", aaveUsdcValue);

        // Calculate proportional split based on USD values
        uint256 totalUsdValue = fluidUsdcValue + aaveUsdcValue;

        if (totalUsdValue > 0) {
            fluidSharesOut = (redeemShares * fluidUsdcValue) / totalUsdValue;
            aaveSharesOut = redeemShares - fluidSharesOut; // Use subtraction to avoid rounding errors

            console2.log("fluidSharesOut", fluidSharesOut);
            console2.log("aaveSharesOut", aaveSharesOut);
        }

        return (fluidSharesOut, aaveSharesOut);
    }

    function _calculateVaultShares7540Underlying(
        uint256 redeemShares,
        address vault1,
        address vault2
    )
        internal
        view
        returns (uint256 vault1SharesOut, uint256 vault2SharesOut)
    {
        // Get current shares in each vault
        uint256 vault1Shares = IERC4626(vault1).balanceOf(address(strategy));
        uint256 vault2Shares = IERC20Metadata(IERC7540(vault2).share()).balanceOf(address(strategy));

        // Convert shares to underlying asset values
        uint256 vault1UsdcValue = IERC4626(vault1).convertToAssets(vault1Shares);
        uint256 vault2UsdcValue = IERC7540(vault2).convertToAssets(vault2Shares);

        console2.log("---vault1SharesBalance", vault1Shares);
        console2.log("---vault2SharesBalance", vault2Shares);

        console2.log("---vault1UsdcValue", vault1UsdcValue);
        console2.log("---vault2UsdcValue", vault2UsdcValue);

        // Calculate proportional split based on USD values
        uint256 totalUsdValue = vault1UsdcValue + vault2UsdcValue;

        if (totalUsdValue > 0) {
            vault1SharesOut = (redeemShares * vault1UsdcValue) / totalUsdValue;
            vault2SharesOut = redeemShares - vault1SharesOut;

            console2.log("---vault1SharesOut", vault1SharesOut);
            console2.log("---vault2SharesOut", vault2SharesOut);
        }

        return (vault1SharesOut, vault2SharesOut);
    }

    /**
     * @notice Overrides the super ledger setup to have fee = 0
     */
    function _overrideSuperLedgerSetUp() internal {
        configSuperLedger = ISuperLedgerConfiguration(_getContract(ETH, SUPER_LEDGER_CONFIGURATION_KEY));
        superLedgerETH = ISuperLedger(_getContract(ETH, SUPER_LEDGER_KEY));

        // Get the existing yield source oracle IDs that were created with MANAGER address
        bytes32 erc4626OracleId = keccak256(abi.encodePacked(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER));
        bytes32 erc7540OracleId = keccak256(abi.encodePacked(bytes32(bytes(ERC7540_YIELD_SOURCE_ORACLE_KEY)), MANAGER));

        // Get the oracle addresses
        address erc4626Oracle = _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY);
        address erc7540Oracle = _getContract(ETH, ERC7540_YIELD_SOURCE_ORACLE_KEY);

        // Create configs for both ERC4626 and ERC7540 oracles
        ISuperLedgerConfiguration.YieldSourceOracleConfigArgs[] memory configs =
            new ISuperLedgerConfiguration.YieldSourceOracleConfigArgs[](2);
        configs[0] = ISuperLedgerConfiguration.YieldSourceOracleConfigArgs({
            yieldSourceOracle: erc4626Oracle,
            feePercent: 0,
            feeRecipient: address(this),
            ledger: address(superLedgerETH)
        });
        configs[1] = ISuperLedgerConfiguration.YieldSourceOracleConfigArgs({
            yieldSourceOracle: erc7540Oracle,
            feePercent: 0,
            feeRecipient: address(this),
            ledger: address(superLedgerETH)
        });

        bytes32[] memory yieldSourceOracleIds = new bytes32[](2);
        yieldSourceOracleIds[0] = erc4626OracleId;
        yieldSourceOracleIds[1] = erc7540OracleId;

        // Propose the configuration changes to set fees to 0
        vm.prank(MANAGER);
        configSuperLedger.proposeYieldSourceOracleConfig(yieldSourceOracleIds, configs);

        // Wait for the timelock period (1 week)
        vm.warp(block.timestamp + 1 weeks);

        // Accept the proposals
        vm.prank(MANAGER);
        configSuperLedger.acceptYieldSourceOracleConfigProposal(yieldSourceOracleIds);
    }

    /**
     * @notice Resizes an array of addresses to the specified length
     * @param array The original array to resize
     * @param newLength The new length for the array
     * @return A new array with the specified length containing elements from the original array
     */
    function _resizeAddressArray(address[] memory array, uint256 newLength) internal pure returns (address[] memory) {
        address[] memory newArray = new address[](newLength);
        for (uint256 i = 0; i < newLength; i++) {
            newArray[i] = array[i];
        }
        return newArray;
    }

    /**
     * @notice Resizes an array of uint256 to the specified length
     * @param array The original array to resize
     * @param newLength The new length for the array
     * @return A new array with the specified length containing elements from the original array
     */
    function _resizeUint256Array(uint256[] memory array, uint256 newLength) internal pure returns (uint256[] memory) {
        uint256[] memory newArray = new uint256[](newLength);
        for (uint256 i = 0; i < newLength; i++) {
            newArray[i] = array[i];
        }
        return newArray;
    }

     /// @notice Helper function to set vault PPS to 0 for testing zero PPS scenarios
    /// @dev Exactly matches _updateSuperVaultPPS but forces PPS to 0
    /// @param strategyAddr The strategy address
    function _updateSuperVaultPPS_ToZero(address strategyAddr) internal {
        UpdatePPSVars memory vars;

        // Force PPS to 0 for testing
        vars.pps = 0;

        // Get the current timestamp for the signature
        vars.timestamp = block.timestamp;

        // Set the additional parameters as in _updateSuperVaultPPS
        vars.ppsStdev = 0;
        vars.validatorSet = 1;
        vars.totalValidators = 1;

        // Create the message hash with all parameters (exactly as in _updateSuperVaultPPS)
        bytes32 structHash = keccak256(
            abi.encodePacked(
                ecdsappsOracle.UPDATE_PPS_TYPEHASH(),
                strategyAddr,
                vars.pps,
                vars.ppsStdev,
                vars.validatorSet,
                vars.totalValidators,
                vars.timestamp,
                ecdsappsOracle.noncePerStrategy(strategyAddr)
            )
        );
        vars.ethSignedMessageHash = MessageHashUtils.toTypedDataHash(ecdsappsOracle.domainSeparator(), structHash);

        // Create signature (r, s, v) components using VALIDATOR_KEY (exactly as in _updateSuperVaultPPS)
        (vars.v, vars.r, vars.s) = vm.sign(VALIDATOR_KEY, vars.ethSignedMessageHash);

        // Combine the signature components into a single bytes signature
        vars.signature = abi.encodePacked(vars.r, vars.s, vars.v);

        // Create an array of proofs with the signature
        vars.proofs = new bytes[](1);
        vars.proofs[0] = vars.signature;

        // Call batchUpdatePPS on the ECDSAPPSOracle (exactly as in _updateSuperVaultPPS)
        address[] memory strategies = new address[](1);
        strategies[0] = strategyAddr;
        
        bytes[][] memory proofsArray = new bytes[][](1);
        proofsArray[0] = vars.proofs;
        
        uint256[] memory ppss = new uint256[](1);
        ppss[0] = vars.pps;
        
        uint256[] memory ppsStdevs = new uint256[](1);
        ppsStdevs[0] = vars.ppsStdev;
        
        uint256[] memory validatorSets = new uint256[](1);
        validatorSets[0] = vars.validatorSet;
        
        uint256[] memory totalValidators = new uint256[](1);
        totalValidators[0] = vars.totalValidators;
        
        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = vars.timestamp;

        ecdsappsOracle.updatePPS(
            IECDSAPPSOracle.UpdatePPSArgs({
                strategies: strategies,
                proofsArray: proofsArray,
                ppss: ppss,
                ppsStdevs: ppsStdevs,
                validatorSets: validatorSets,
                totalValidators: totalValidators,
                timestamps: timestamps
            })
        );
    }

    /**
     * @notice Updates max PPS slippage to BPS_PRECISION (100%)
     */
    function _updateMaxPPSSlippageToMax() internal {
        vm.prank(MANAGER);
        strategy.updateMaxPPSSlippage(BPS_PRECISION);
    }

    /**
     * @notice Updates PPS to a specific value by manipulating the underlying vaults
     * @param strategyAddr The strategy address
     * @param vault_ The vault address
     * @param targetPPS The target PPS value to achieve
     * @dev This function simulates yield by dealing additional assets to the underlying vaults
     */
    function _updatePPSToTarget(address strategyAddr, address vault_, uint256 targetPPS) internal {
        uint256 currentPPS = aggregator.getPPS(strategyAddr);
        uint256 currentTotalSupply = SuperVault(vault_).totalSupply();

        if (currentTotalSupply == 0) {
            // No shares exist, can't update PPS
            return;
        }

        // Calculate how much additional assets we need to reach target PPS
        uint256 currentTotalAssets = currentPPS * currentTotalSupply / SuperVault(vault_).PRECISION();
        uint256 targetTotalAssets = targetPPS * currentTotalSupply / SuperVault(vault_).PRECISION();

        if (targetTotalAssets > currentTotalAssets) {
            uint256 additionalAssets = targetTotalAssets - currentTotalAssets;

            // Deal additional assets to the underlying vaults proportionally
            uint256 fluidVaultAssets = asset.balanceOf(address(fluidVault));
            uint256 aaveVaultAssets = asset.balanceOf(address(aaveVault));
            uint256 totalUnderlyingAssets = fluidVaultAssets + aaveVaultAssets;

            if (totalUnderlyingAssets > 0) {
                uint256 fluidVaultAdditional = additionalAssets * fluidVaultAssets / totalUnderlyingAssets;
                uint256 aaveVaultAdditional = additionalAssets - fluidVaultAdditional;

                if (fluidVaultAdditional > 0) {
                    deal(address(asset), address(fluidVault), fluidVaultAssets + fluidVaultAdditional);
                }
                if (aaveVaultAdditional > 0) {
                    deal(address(asset), address(aaveVault), aaveVaultAssets + aaveVaultAdditional);
                }
            }
        }

        // Update PPS after asset manipulation
        _updateSuperVaultPPS(strategyAddr, vault_);
    }

    /// @notice Calculate performance fee for one controller
    /// @param controller Controller address
    /// @param redeemShares Redeem shares
    /// @param yieldSources Yield sources
    /// @return superformFee Superform fee
    /// @return recipientFee Recipient fee
    /// @return expectedControllerAssets Expected controller assets
    function _calculatePerformanceFee(
        uint256 redeemShares,
        address controller,
        address[] memory yieldSources
    )
        internal
        view
        returns (uint256 superformFee, uint256 recipientFee, uint256 expectedControllerAssets)
    {
        ISuperVaultStrategy.SuperVaultState memory state = strategy.getSuperVaultState(controller);
        uint256 controllerRequestedAmount = state.pendingRedeemRequest;

        uint256 netAssetsToBeWithdrawn;
        for (uint256 i; i < yieldSources.length; ++i) {
            address yieldSource = yieldSources[i];
            uint256 assets = vault.convertToAssets(redeemShares);
            uint256 underlyingShares =
                IYieldSourceOracle(oracle4626).getShareOutput(yieldSource, vault.asset(), assets);
            uint256 expectedAssets = IERC4626(yieldSource).previewRedeem(underlyingShares);
            netAssetsToBeWithdrawn += expectedAssets;
        }

        uint256 historicalAssets = _calculateCostBasis(state, controllerRequestedAmount);

        uint256 grossControllerAssets = Math.mulDiv(
            controllerRequestedAmount, netAssetsToBeWithdrawn, controllerRequestedAmount, Math.Rounding.Floor
        );

        // Cap against PPS
        uint256 controllerAssetsAtPPS =
            Math.mulDiv(controllerRequestedAmount, strategy.getStoredPPS(), vault.PRECISION(), Math.Rounding.Floor);
        if (grossControllerAssets > controllerAssetsAtPPS) {
            grossControllerAssets = controllerAssetsAtPPS;
        }

        (expectedControllerAssets, superformFee, recipientFee) = _deriveFeesFromAssets(grossControllerAssets, historicalAssets);
    }

    /// @notice Calculate cost basis for requested shares using weighted average approach
    /// @param state User's vault state
    /// @param requestedShares Shares being redeemed
    function _calculateCostBasis(
        ISuperVaultStrategy.SuperVaultState memory state,
        uint256 requestedShares
    )
        internal
        pure
        returns (uint256 costBasis)
    {
        // Calculate cost basis proportionally
        costBasis = requestedShares.mulDiv(state.accumulatorCostBasis, state.accumulatorShares, Math.Rounding.Floor);
    }

    /// @notice Derive fees from assets
    /// @param grossAssets Gross assets
    /// @param historicalAssets Historical assets
    /// @return netAssets Net assets
    /// @return superformFee Superform fee
    /// @return recipientFee Recipient fee
    function _deriveFeesFromAssets(
        uint256 grossAssets,
        uint256 historicalAssets
    )
        internal
        view
        returns (uint256 netAssets, uint256 superformFee, uint256 recipientFee)
    {
        // Apply fees only on profit
        if (grossAssets > historicalAssets) {
            netAssets = grossAssets;
            uint256 profit = grossAssets - historicalAssets;
            ISuperVaultStrategy.FeeConfig memory feeConfig = strategy.getConfigInfo();
            uint256 performanceFeeBps = feeConfig.performanceFeeBps;
            uint256 totalFee = profit.mulDiv(performanceFeeBps, BPS_PRECISION, Math.Rounding.Ceil);

            if (totalFee > 0) {
                // Calculate Superform's portion of the fee using revenueShare from SuperGovernor
                superformFee = Math.mulDiv(
                    totalFee,
                    superGovernor.getFee(FeeType.SUPER_VAULT_PERFORMANCE_FEE),
                    BPS_PRECISION,
                    Math.Rounding.Floor
                );
                recipientFee = totalFee - superformFee;
                netAssets -= totalFee;
            }
        } else {
            netAssets = grossAssets; // No fee
            return (netAssets, 0, 0);
        }
    }

        function __prepareDepositHookData(
        uint256 depositAmount,
        address assetToDeposit,
        address vault1,
        address vault2
    ) private view returns (
        address[] memory fulfillHooksAddresses,
        bytes[] memory fulfillHooksData,
        uint256[] memory expectedAssetsOrSharesOut
    ) {
        address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        fulfillHooksAddresses = new address[](2);
        fulfillHooksAddresses[0] = depositHookAddress;
        fulfillHooksAddresses[1] = depositHookAddress;

        fulfillHooksData = new bytes[](2);

        // Split the deposit between two hooks
        uint256 halfAmount = depositAmount / 2;
        fulfillHooksData[0] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            vault1,
            assetToDeposit,
            halfAmount,
            false,
            address(0),
            0
        );

        fulfillHooksData[1] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            vault2,
            assetToDeposit,
            depositAmount - halfAmount,
            false,
            address(0),
            0
        );

        expectedAssetsOrSharesOut = new uint256[](2);
        expectedAssetsOrSharesOut[0] = IERC4626(address(vault1)).convertToShares(halfAmount);
        expectedAssetsOrSharesOut[1] = IERC4626(address(vault2)).convertToShares(depositAmount - halfAmount);
    }
    function __executeDepositHooks(
        uint256 depositAmount,
        address strat,
        address[] memory fulfillHooksAddresses,
        bytes[] memory fulfillHooksData,
        uint256[] memory expectedAssetsOrSharesOut
    ) private {
        bytes[] memory argsForProofs = new bytes[](2);
        argsForProofs[0] = ISuperHookInspector(fulfillHooksAddresses[0]).inspect(fulfillHooksData[0]);
        argsForProofs[1] = ISuperHookInspector(fulfillHooksAddresses[1]).inspect(fulfillHooksData[1]);

        vm.startPrank(MANAGER);
        SuperVaultStrategy(payable(strat)).executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: fulfillHooksAddresses,
                hookCalldata: fulfillHooksData,
                expectedAssetsOrSharesOut: expectedAssetsOrSharesOut,
                globalProofs: _getMerkleProofsForHooks(fulfillHooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](2)
            })
        );
        vm.stopPrank();

        (uint256 pricePerShare) = _getSuperVaultPricePerShare();
        uint256 shares = depositAmount.mulDiv(SuperVaultStrategy(payable(strat)).PRECISION(), pricePerShare);

        _trackDeposit(accountEth, shares, depositAmount);
    }
}
